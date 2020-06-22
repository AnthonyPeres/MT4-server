//+------------------------------------------------------------------+
//|                                                    Functions.mqh |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

/* Ping le client */
void ping() {
    Print("Ping" + TimeToStr(TimeCurrent(), TIME_SECONDS));
    return "";
}

/* Créer un nouvel ordre, direct ou en attente */
void order_open(
    int id_requete,
    string symbol,
    string cmd,
    double volume,
    double price, 
    int slippage,
    double stoploss,
    double takeprofit,
    string comment,
    int magic_number
) {
    int ticket = OrderSend(symbol, cmd, volume, price, slippage, stoploss, takeprofit, comment, magic_number);
    if (ticket < 0) {
        Print("OrderSend failed with error #", GetLastError());
        return id_requete + "|REPLY_FAILED|" + GetLastError();
    } else {
        Print("OrderSend placed succesfully");
        return rep += id_requete + "|REPLY_OK|" + ticket; 
    }
}

/* Modifier un ordre, ouvert ou en attente */
void order_modify(
    int id_requete,
    int ticket,
    double price, 
    double stoploss,
    double takeprofit
) {
    Print("Order Modify");
    return "";
}

/* Supprimer un ordre en attente */
void pending_order_delete(
    int ticket
) {
    Print("Pending order delete");
    return "";
}

/* Supprimer tout les ordres en attente */
void pending_order_delete_all(
    string symbol
) {
    Print("Pending order delete all");
    return "";
}

/* Cloturer un ordre */
void market_order_close(
    int ticket
) {
    Print("Market order close");
    return "";
}

/* Cloturer tout les ordres */
void market_order_close_all(
    string symbol
) {
    Print("Market order close all");
    return "";
}

/* Obtenir tout les ordres du compte */
void orders() {
    Print("Orders");
    return "";
}

/* Obtenir le taux actuel du symbole */
void rates(
    string symbol
) {
    Print("Rates");
    return "";
}

/* Obtenir les informations du compte */
void account() {
    Print("Account");
    return "";
}