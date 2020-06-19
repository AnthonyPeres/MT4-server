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
    Print("Ping");
    return "";
}

/* Créer un nouvel ordre, direct ou en attente */
string order_open(
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
    Print("Order Open");
    return "";
}

/* Modifier un ordre, ouvert ou en attente */
string order_modify(
    int ticket,
    double price, 
    double stoploss,
    double takeprofit, 
) {
    Print("Order Modify");
    return "";
}

/* Supprimer un ordre en attente */
string pending_order_delete(
    int ticket
) {
    Print("Pending order delete");
    return "";
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
    int ticket
) {
    Print("Market order close");
    return "";
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