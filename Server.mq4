//+------------------------------------------------------------------+
//|                                                       Server.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Zmq/Zmq.mqh>
#include "Functions.mqh"

extern string ClientID = "MT4_SERVER";
extern string host = "*";
extern string protocol = "tcp";
extern int REP_PORT = 5555;
extern int PUSH_PORT = 5556;
extern int TIMER = 1;

// Create ZMQ Context
Context context(ClientID); 

// Create REP Socket
Socket repSocket(context, ZMQ_REP);

// Create PUSH Socket
Socket pushSocket(context, ZMQ_PUSH);

// Message
ZmqMsg request;
char data[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Le timer est de 1 secondes. 
   EventSetTimer(TIMER);
   
   // Binding RepSocket
   Print("[REP] Binding MT4 Server to Socket on port " + IntegerToString(REP_PORT)+ "...");
   repSocket.bind(StringFormat("%s://%s:%d", protocol, host, REP_PORT));
   
   // Binding PushSocket
   Print("[PUSH] Binding MT4 Server to Socket on port " + IntegerToString(PUSH_PORT) + "...");
   pushSocket.bind(StringFormat("%s://%s:%d", protocol, host, PUSH_PORT));
   
   // Durée maximal en ms pendant laquelle le thread tentera d'envoyer des messages
   repSocket.setLinger(5000);
   
   // Nombre de messages en mémoire tampon (file d'attente) avant de bloquer le socket.
   repSocket.setSendHighWaterMark(10);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // On détruit le timer
   EventKillTimer();
   
   Print("[REP] Unbinding MT4 Server from Socket on Port " + IntegerToString(REP_PORT) + "...");
   repSocket.unbind(StringFormat("%s://%s:%d", protocol, host, REP_PORT));
   
   Print("[PUSH] Unbinding MT4 Server from Socket on Port " + IntegerToString(PUSH_PORT) + "...");
   pushSocket.unbind(StringFormat("%s://%s:%d", protocol, host, PUSH_PORT));
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   repSocket.recv(request, true);       // Get client's request, but don't wait.
   MessageHandler(request);             // Process.
}

//+------------------------------------------------------------------+
//| Other functions                                                  |
//+------------------------------------------------------------------+

/* Traitement de la requête. */
void MessageHandler(ZmqMsg &request) {
    
   // Le message qui va être renvoyé
   ZmqMsg reply;

   // Le message pour plus tard
   string message_decoupe[];

   if (request.size() > 0) {

      // On recupere les données de la requête
      ArrayResize(data, request.size());
      request.getData(data);
      string data_str = CharArrayToString(data);

      // On analyse le message
      ParseZmqMessage(data_str, message_decoupe);

      // On l'interprete
      InterpretZmqMessage(pushSocket, message_decoupe);

      // On construit la réponse
      ZmqMsg reply(StringFormat("[SERVER] Processing: %s", data_str));
      repSocket.send(reply);

   } else {
      // On a reçu aucune donnée
   }
}

/* Analyse le message. */
void ParseZmqMessage(string &message, string &retArray[]) {
   Print("Analyse: " + message);
   
   string sep = "|";
   ushort u_sep = StringGetCharacter(sep,0);
   
   int splits = StringSplit(message, u_sep, retArray);
   
   for(int i = 0; i < splits; i++) {
      Print("(" + i + ") " + retArray[i]);
   }
}

/* Interprete le message. */
void InterpretZmqMessage(Socket &pSocket, string& compArray[]) {

   Print("ZMQ: Interpreting message...");

   int action = 0;
   
   if (compArray[1] == "PING") {
      action = 1;
   } else if (compArray[1] == "ORDER_OPEN") {
      action = 2;
   } else if (compArray[1] == "ORDER_MODIFY") {
      action = 3;
   } else if (compArray[1] == "PENDING_ORDER_DELETE") {
      action = 4;
   } else if (compArray[1] == "PENDING_ORDER_DELETE_ALL") {
      action = 5;
   } else if (compArray[1] == "MARKET_ORDER_CLOSE") {
      action = 6;
   } else if (compArray[1] == "MARKET_ORDER_CLOSE_ALL") {
      action = 7;
   } else if (compArray[1] == "ORDERS") {
      action = 8;
   } else if (compArray[1] == "RATES") {
      action = 9;
   } else if (compArray[1] == "ACCOUNT") {
      action = 10;
   } 

   switch (action) {
      case 1:
         ping();
         break;

      case 2: 
         if (compArray[3] == "OP_BUY") {
            order_open("", "", 0.0, 0.0, 0, 0.0, 0.0, "", 0);
         } else if (compArray[3] == "OP_SELL") {
            order_open("", "", 0.0, 0.0, 0, 0.0, 0.0, "", 0);
         } else if (compArray[3] == "OP_BUYLIMIT") {
            order_open("", "", 0.0, 0.0, 0, 0.0, 0.0, "", 0);
         } else if (compArray[3] == "OP_SELLLIMIT") {
            order_open("", "", 0.0, 0.0, 0, 0.0, 0.0, "", 0);
         } else if (compArray[3] == "OP_BUYSTOP") {
            order_open("", "", 0.0, 0.0, 0, 0.0, 0.0, "", 0);
         } else if (compArray[3] == "OP_SELLSTOP") {
            order_open("", "", 0.0, 0.0, 0, 0.0, 0.0, "", 0);
         } 
         break;
      
      case 3:
         order_modify(0, 0.0, 0.0, 0.0);
         break;

      case 4: 
         pending_order_delete(0);
         break;

      case 5: 
         pending_order_delete_all("");
         break;

      case 6: 
         market_order_close(0);
         break;

      case 7: 
         market_order_close_all("");
         break;

      case 8: 
         orders();
         break;

      case 9: 
         rates("");
         break;

      case 10: 
         account();
         break;

      default: 
         break;
   }
}