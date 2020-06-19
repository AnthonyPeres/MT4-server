# MT4-server

Couche de communication demande / réponse entre MetaTrader 4 et l’application développée en Python.
La communication est effectuée grâce à ZeroMQ (http://zeromq.org/) 
A l’avenir, elle pourrait être étendu pour prendre en charge plus de protocoles.

Un analyseur de message est implémenté pour facilité la tâche d’interprétation des messages.
Les messages analysés créent des liaisons pour les informations de compte, les commandes de comptes et la gestion des commandes.


## Bibliothèques

[mql-zmq] (https://github.com/dingmaotu/mql-zmq) 

## Installation 

Installer la bibliothèque [mql-zmq].
Copier ce programme dans le dossier des Experts Advisors de MetaTrader 4 et le compiler dans MetaEditor.
Activer le Trading Automatique dans l’application MetaTrader 4.

## Utilisation 

Ajouter l’EA Server à votre graphique.
Activer « Autoriser le trading en direct » et « Autoriser les importations de DDL ».
Configurer ensuite le serveur dans l’onglet Entrées selon vos besoins.

## Deux serveurs

Deux serveurs démarrent avec l'EA.
1. Le premier est le serveur REP qui sert à accepter les messages.
2. Le second est le serveur PUSH qui sert a envoyer les messages ainsi que les événements de mise à jour des données (taux, informations de compte, changement de commandes) au client.

Le second serveur pourra envoyer des données sous format json au client (données, indicateurs...).

## Protocole

Le protocole utilisé est le tcp. 
Les messages de demande / réponse sont des chaînes de caractères séparées par le caractère `|` (string split).

## Déroulement du programme

### Initialisation

Le serveur passe tout d'abord par une phase d'initialisation. Durant celle-ci, il va bind le client

### Boucle principale

Le serveur va recevoir des demandes, sans pour autant les attendre. 
Lorsqu'il reçoit une demande, il va automatiquement la transformer en chaîne de caractère puis va la découper de sorte à pouvoir identifier chaque partie de cette demande.

### Déinitialisation

Le serveur s'éteint en passant par une phase de déinitialisation. Durant celle-ci, il va unbind le client

## Demandes

Voici la forme générale d'une demande : `ID|TYPE DE DEMANDE|ARGUMENTS`

Les types de demandes sont : 

| TYPE DE DEMANDE                            | Description                                                    |
| : -----------------------------------------  | : ------------------------------------------------ |
| `PING`                                                    | Ping le client                                                 |
| `ORDER_OPEN`                                        | Créer un nouvel ordre                                  |
| `ORDER_MODIFY`                                    | Modifier un ordre                                          |
| `PENDING_ORDER_DELETE`                   | Supprimer un ordre en attente                     |
| `PENDING_ORDER_DELETE_ALL`           | Supprimer tout les ordres en attente           |
| `MARKET_ORDER_CLOSE`                        | Cloturer un ordre ouvert                              |
| `MARKET_ORDER_CLOSE_ALL`                | Cloturer tout les ordres ouverts                  |
| `ORDERS`                                                 | Obtenir tout les ordres du compte              |
| `RATES`                                                   | Obtenir le taux actuel du symbole               |
| `ACCOUNT`                                               | Obtenir les informations du compte            |

### Trade opération

Pour ouvrir un ordre de marché ou placer des demandes d'ordres en attente.
Voir : (https://docs.mql4.com/constants/tradingconstants/orderproperties)

Les opérations sont : 

| OPERATION_TYPE | Description                                                          |
| : --------------------  | : ---------------------------------------------------- |
| `OP_BUY`                  | Opération d'achat.                                              |
| `OP_SELL`                | Opération de vente.                                            |
| `OP_BUYLIMIT`        | Limite d'achat en attente de commande.           |
| `OP_SELLLIMIT`      | Limite de vente en attente de commande.         |
| `OP_BUYSTOP`          | Acheter arrêter la commande en attente.           |
| `OP_SELLSTOP`        | Vendre un ordre en attente d'arrêt.                    |

### Exemples de demandes

Modifier une commande : 

```
1|PENDING_ORDER_MODIFY|143928208|103,483|292,228|393,292
```

Supprimer la commande en attente : 

```
1|PENDING_ORDER_DELETE|13382972
```

Obtenir les taux actuels pour USDJPY : 

```
3|RATES|USDJPY
```

### Gestion des id de demande

L'identifiant de la demande doit être unique avec chaque demande (par exemple, incrémenté int).

Mais dans certains cas, vous souhaiterez peut-être utiliser des valeurs statiques, comme "COMPTE" - qui pourraient envoyer périodiquement des informations de compte au client afin qu'il puisse disposer de données à jour sur le compte.

## Réponses

Voici la forme d'une réponse : `ID|ÉTAT DE LA RÉPONSE`

L'id étant l'id de la demande correspondante.
Les états de réponse sont : 

| ÉTAT DE RÉPONSE    | Description                     |
| : ----------------------- | : -------------------------- |
| `REPLY_OK`                 | La réponse est réussie.  |
| `REPLY_FAILED`         | La réponse a échoué.    |

### Réponse réussie

En cas de succès, les autres valeurs sont des valeurs de réponse.

##### Exemple de réponse réussie

```
2|REPLY_OK|109,3939|393,3938|USDJPY
```
2 est l'id de la demande
REPONSE|OK indique que la réponse du serveur a réussi et que le reste du message peut être analysé en fonction du type de la demande

### Réponse échec

En cas d'échec, la troisième valeur indique le code d'erreur. Aucune autre valeur n'est renvoyée.

#### Exemple de réponse échec

```
2|REPLY_FAILED|134
```
2 est l'id de la demande
REPONSE|FAILED indique que la réponse du serveur a échoué et la troisième valeur est le code d'erreur de «134» qui signifie «La marge libre est insuffisante" 

## Les demandes

------------------------------------------------------------------------------------------------------------------------------------------
### PING

Ping le client.

#### Paramètres de la demande

Aucun.

#### Exemple de demande

```
100|PING
```

#### Valeur de réponse

Horodatage actuel du client MT4 en secondes

#### Exemple de réponse

```
100|REPLY_OK|1529834816
```

------------------------------------------------------------------------------------------------------------------------------------------
### ORDER_OPEN

Créer un nouvel ordre, direct ou en attente. 

#### Paramètres de la demande

`SYMBOL`                String                           Symbole à trader.
`CMD`                      String                           Opération commerciale
`VOLUME`                Double | Chaine           Volume d'échange.
`PRICE`                  Double                         Valeur littérale ou modificateur (# modificateurs de prix) pour le prix de la commande.
`SLIPPAGE`            Int                                Glissement de prix maximum pour les commandes d'achat ou de vente.
`STOPLOSS`            Double | Chaîne           Valeur littérale ou modificateur (# prix-modificateurs) pour le niveau de stop loss.
`TAKEPROFIT`        Double | Chaîne           Valeur littérale ou modificateur (# prix-modificateurs) pour le niveau de take profit.
`COMMENT`              String                           La limite est de 27 caractères. N'utilisez pas le tuyau «|». Peut être vide : Commentaire.
`MAGIC_NUMBER`    Int                                Commande le nombre magique. Peut être utilisé comme identifiant défini par l'utilisateur.

```
CMD : 
    OP_BUY           
    OP_SELL    
    OP_BUYLIMIT 
    OP_SELLLIMIT
    OP_BUYSTOP  
    OP_SELLSTOP`
```

#### Exemple de demande

```
236|TRADE_OPEN|USDJPY|OP_BUY|1|108.848|0|0|0|message de commentaire affiché ici|123|0
```

#### Paramètres de la réponse

Ticket de commande `TICKET` reçu du serveur de commerce.

#### Exemple de réponse

```
236|REPLY_OK|140602286
```

------------------------------------------------------------------------------------------------------------------------------------------
### ORDER_MODIFY

Modifier un ordre, ouvert ou en attente.

#### Paramètres de la demande

`TICKET`                Int                                Billet de la commande.
`PRICE`                  Double                        Valeur littérale ou modificateur (# modificateurs de prix) pour le prix de la commande.
`STOPLOSS`            Double | Chaîne          Valeur littérale ou modificateur (# prix-modificateurs) pour le niveau de stop loss.
`TAKEPROFIT`        Double | Chaîne          Valeur littérale ou modificateur (# prix-modificateurs) pour le niveau de take profit.
`EXPIRATION`        Datetime                     Délai d'expiration de la commande en attente

#### Exemple de demande

```
312|TRADE_MODIFY|140602286|108,252|107,525|109,102
```

#### Valeurs de réponse

Ticket de commande `TICKET` reçu du serveur de commerce.

#### Exemple de réponse

```
312|REPLY_OK|140602286
```

------------------------------------------------------------------------------------------------------------------------------------------
### PENDING_ORDER_DELETE

Supprimer un ordre en attente.

#### Paramètres de la demande

`TICKET`                Int                                Billet de la demande

#### Exemple de demande

```
318|TRADE_DELETE|140602286
```

#### Valeurs de réponse

Ticket de commande `TICKET` reçu du serveur de commerce.

#### Exemple de réponse

```
`318|REPLY_OK|140602286
```

------------------------------------------------------------------------------------------------------------------------------------------
### PENDING_ORDER_DELETE_ALL

Supprimer tout les ordres en attente.

#### Paramètres de la demande

`SYMBOL`              String                            Symbole pour lequel les commandes en attente doivent être supprimées.

#### Exemple de demande

```
345|DELETE_ALL_PENDING|USDJPY
```

#### Valeurs de réponse

`DELETE_COUNT` : Int : Nombre de commandes en attente supprimées.

#### Exemple de réponse

```
345|REPLY_OK|2
```

------------------------------------------------------------------------------------------------------------------------------------------
### MARKET_ORDER_CLOSE

Cloturer un ordre.

#### Paramètres de la demande

`TICKET`             Int                                   Billet d'ordre de marché

#### Exemple de demande

```
380|CLOSE_MARKET_ORDER|140612332
```

#### Valeurs de réponse

`TICKET` : Billet de commande

#### Exemple de réponse

```
380|REPLY_OK|140612332
```

------------------------------------------------------------------------------------------------------------------------------------------
### MARKET_ORDER_CLOSE_ALL

Cloturer tout les ordres.

#### Paramètres de la demande

`SYMBOL`              String                            Symbole pour lequel les ordres doivent être fermées.

#### Exemple de demande

```
383|CLOSE_MARKER_ORDER_ALL|USDJPY
```

#### Valeurs de réponse

`DELETED_COUNT` : Nombre de commandes en attentes supprimées

#### Exemple de réponse

```
380|REPLY_OK|3
```

------------------------------------------------------------------------------------------------------------------------------------------
### ORDERS

Obtenir tout les ordres du compte.
Dans ce cas spécifique, les valeurs de commande sont séparées par une virgule `,` et les commandes sont séparées par un tuyau `|`. 
Ainsi, après avoir fractionné la réponse, vous aurez les commandes que vous auriez probablement besoin de fractionner à 
nouveau avec `,` comme séparateur (par exemple, `response.split('|').map(item => item.split(','))`).

#### Paramètres de la demande

Aucun.

#### Exemple de demande

```
467|ORDERS
```

#### Valeurs de réponse

`ORDRE` : Les commandes avec des valeurs séparées par des virgules `,`.
`TICKET` : Billet de commande
`OPEN_TIME` : commande prix ouvert.
`TYPE` : [type d'ordre] (# opérations commerciales).
`LOTS` : Volume de commande
`SYMBOL` : Symbole de commande
`OPEN_PRICE` : Commande prix ouvert.

#### Exemple de réponse

```
467|REPLY_OK|140617577,2018.05.31 10:40,1,0.01,EURUSD,1.17017,|140623054,2018.05.31 14:20,3,0.11,USDJPY,130.72600
```

------------------------------------------------------------------------------------------------------------------------------------------
### RATES

Obtenir le taux actuel du symbole.

#### Paramètres de la demande

`SYMBOL`                        String                  Symbole pour lequel les ordres doivent être fermées.

#### Exemple de demande

```
397|RATES|USDJPY
```

#### Valeurs de réponse

`BID` : Prix actuel de l'enchère
`ASK` : Prix actuel demandé
`SYMBOL` : Le symbole

#### Exemple de réponse

```
397|REPLY_OK|108,926000|108,947000|USDJPY
```

------------------------------------------------------------------------------------------------------------------------------------------
### ACCOUNT

Obtenir les informations du compte.

#### Paramètres de la demande

Aucun 

#### Exemple de demande

```
415|ACCOUNT
```

#### Valeurs de réponse

`DEVISE` : devise du compte.
`BALANCE` : solde du compte dans la devise du dépôt.
`PROFIT` : bénéfice courant d'un compte dans la devise de dépôt.
`EQUITY_MARGIN` : fonds propres du compte dans la devise du dépôt.
`MARGIN_FREE` : marge libre d'un compte dans la devise de dépôt.
`MARGIN_LEVEL` : niveau de marge du compte en pourcentage.
`MARGIN_SO_CALL` : niveau d'appel de marge.
`MARGIN_SO_SO` : niveau d'arrêt de marge.

#### Exemple de réponse

```
415|REPLY_OK|USD|10227.43|-129.46|10097.97|4000.00|6097.97|252.45|50.00|20.00
```

------------------------------------------------------------------------------------------------------------------------------------------

## Côté MT4

### Ouvrir un ordre ou le mettre en attente

Pour ouvrir un ordre, la fonction est [OrderSend](https://docs.mql4.com/trading/ordersend).

```
int OrderSend (
    string     symbol,                  // symbol: Symbol for trading
    int        cmd,                     // operation: Operation type. It can be any of the Trade operation enumeration
    double     volume,                  // volume: Number of lots
    double     price,                   // price: Order price
    int        slippage,                // slippage: Maximum price slippage for buy or sell orders
    double     stoploss,                // stop loss: Stop loss level
    double     takeprofit,              // take profit: Take profit level
    string     comment = NULL,          // comment: Order comment text. Last part of the comment may be changed by server
    int        magic = 0,               // magic number: Order magic number. May be used as user defined identifier
    datetime   expiration = 0,          // pending order expiration: Order expiration time (for pending orders only)
    color      arrow_color = clrNONE    // color: Color of the opening arrow on the chart. If parameter is missing or has CLR_NONE value opening arrow is not drawn on the chart
);

Returned value : 
Number of the ticket assigned to the order by the trade server or -1 if it fails. 
To get additional error information, one has to call the GetLastError() function.
```

### Modifier un ordre, ouvert ou en attente

Pour modifier un ordre, la fonction est [OrderModify](https://docs.mql4.com/trading/ordermodify).

```
bool  OrderModify(
    int        ticket,                  // ticket: Unique number of the order ticket
    double     price,                   // price: New open price of the pending order
    double     stoploss,                // stop loss: New StopLoss level
    double     takeprofit,              // take profit: New TakeProfit level
    datetime   expiration,              // expiration: Pending order expiration time
    color      arrow_color              // color: Arrow color for StopLoss/TakeProfit modifications in the chart. If the parameter is missing or has CLR_NONE value, the arrows will not be shown in the chart
);

Returned value : 
If the function succeeds, it returns true, otherwise false. 
To get the detailed error information, call the GetLastError() function.

```

### Supprimer un ordre en attente

Pour supprimer un ordre, la fonction est [OrderDelete](https://docs.mql4.com/trading/orderdelete).

```
bool  OrderDelete(
    int        ticket,                  // ticket: Unique number of the order ticket
    color      arrow_color              // color: Color of the arrow on the chart. If the parameter is missing or has CLR_NONE value arrow will not be drawn on the chart
);

Returned value : 
If the function succeeds, it returns true, otherwise false. 
To get the detailed error information, call the GetLastError() function.
```

### Fermer un ordre ouvert

Pour fermer un ordre, la fonction est [OrderClose](https://docs.mql4.com/trading/orderclose).

```
bool  OrderClose(
    int        ticket,                  // ticket: Unique number of the order ticket
    double     lots,                    // volume: Number of lots
    double     price,                   // close price: Closing price
    int        slippage,                // slippage: Value of the maximum price slippage in points
    color      arrow_color              // color: Color of the closing arrow on the chart. If the parameter is missing or has CLR_NONE value closing arrow will not be drawn on the chart
);

Returned value :
Returns true if successful, otherwise false. 
To get additional error information, one has to call the GetLastError() function.
```
