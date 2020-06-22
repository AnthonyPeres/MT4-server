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

      /* Par exemple, avec l'envoie d'un string : 1|PING, data_str = 1|PING,
       * Dans ParseZmqMessage, on renvoie : 
       * Analyse 1|PING
       *    (0) 1
       *    (1) PING 
       */

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
void InterpretZmqMessage(Socket &pSocket, string& valeurs_requete[]) {

   Print("ZMQ: Interpreting message...");
   
   if (valeurs_requete[1] == "PING") {
   
      ping();
   
   } else if (valeurs_requete[1] == "ORDER_OPEN") {
      order_open(
         valeurs_requete[2],
         valeurs_requete[3],
         StrToDouble(valeurs_requete[4]),
         StrToDouble(valeurs_requete[5]),
         StrToInt(valeurs_requete[6]),
         StrToDouble(valeurs_requete[7]),
         StrToDouble(valeurs_requete[8]),
         valeurs_requete[9],
         StrToInt(valeurs_requete[10])
      )
   } else if (valeurs_requete[1] == "ORDER_MODIFY") {
   
      order_modify(0, 0.0, 0.0, 0.0);
   
   } else if (valeurs_requete[1] == "PENDING_ORDER_DELETE") {
   
      pending_order_delete(0);
   
   } else if (valeurs_requete[1] == "PENDING_ORDER_DELETE_ALL") {
   
      pending_order_delete_all("");
   
   } else if (valeurs_requete[1] == "MARKET_ORDER_CLOSE") {
   
      market_order_close(0);
   
   } else if (valeurs_requete[1] == "MARKET_ORDER_CLOSE_ALL") {
   
      market_order_close_all("");
   
   } else if (valeurs_requete[1] == "ORDERS") {
   
      orders();
   
   } else if (valeurs_requete[1] == "RATES") {
   
      rates("");
   
   } else if (valeurs_requete[1] == "ACCOUNT") {
   
      account();
   
   } 
}