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
string ping() {
    Print("Ping" + TimeToStr(TimeCurrent(), TIME_SECONDS));
    return "";
}

/* Créer un nouvel ordre, direct ou en attente */
string order_open(
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
        return id_requete + "|REPLY_OK|" + ticket; 
    }
}

/* Modifier un ordre, ouvert ou en attente */
string order_modify(
    int id_requete,
    int ticket,
    double price, 
    double stoploss,
    double takeprofit
) {
    bool success = OrderModify(ticket, price, stoploss, takeprofit, 0);
    if (!success) {
        Print("OrderModify failed with error #", GetLastError());
        return id_requete + "|REPLY_FAILED|" + GetLastError();
    } else {
        Print("OrderModify succesfully");
        return id_requete + "|REPLY_OK|" + ticket; 
    }
}

/* Supprimer un ordre en attente */
string pending_order_delete(
    int id_requete,
    int ticket
) {
    bool success = OrderDelete(ticket);
    if (!success) {
        Print("PendingOrderDelete failed with error #", GetLastError());
        return id_requete + "|REPLY_FAILED|" + GetLastError();
    } else {
        Print("PendingOrderDelete succesfully");
        return id_requete + "|REPLY_OK|" + ticket; 
    }
}

/* Supprimer tout les ordres en attente */
string pending_order_delete_all(
    string symbol
) {
    Print("Pending order delete all");
    return "";
}

/* Cloturer un ordre */
string market_order_close(
    int id_requete,
    int ticket
) {
    bool success = OrderClose(ticket,1,Ask,3);
    if (!success) {
        Print("OrderClose failed with error #", GetLastError());
        return id_requete + "|REPLY_FAILED|" + GetLastError();
    } else {
        Print("OrderClose succesfully");
        return id_requete + "|REPLY_OK|" + ticket; 
    }
}

/* Cloturer tout les ordres */
string market_order_close_all(
    string symbol
) {
    Print("Market order close all");
    return "";
}

/* Obtenir tout les ordres du compte */
string orders() {
    Print("Orders");
    return "";
}

/* Obtenir le taux actuel du symbole */
string rates(
    string symbol
) {
    Print("Rates");
    return "";
}

/* Obtenir les informations du compte */
string account() {
    Print("Account");
    return "";
}