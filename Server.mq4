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
#include "Mq4Commands.mqh"

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
   repSocket.recv(request, true);            // Get client's request, but don't wait.
   ZmqMsg reply = MessageHandler(request);   // Process.
   repSocket.send(reply);                    // Send response to the client.

   SendUpdateMessage(pushSocket);            // Send periodical updates to connected sockets.
}

//+------------------------------------------------------------------+
//| Other functions                                                  |
//+------------------------------------------------------------------+

/* Traitement de la requête. */
ZmqMsg MessageHandler(ZmqMsg &request) {
    
   // Le message qui va être renvoyé
   ZmqMsg reply;

   // Le message pour plus tard
   string components[];

   if (request.size() > 0) {

      // On recupere les données de la requête
      ArrayResize(data, request.size());
      request.getData(data);
      string data_str = CharArrayToString(data);

      // On analyse le message
      ParseZmqMessage(data_str, components);

      // On l'interprete
      InterpretZmqMessage(pushSocket, components);

      // On construit la réponse
      ZmqMsg ret(StringFormat("[SERVER] Processing: %s", data_str));
      reply = ret;

   } else {
      // On a reçu aucune donnée
   }

   return reply;
}

/* Analyse le message. */
void ParseZmqMessage(string &message, string &retArray[]) {
   Print("Parsing: " + message);
   
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
   
   if (compArray[0] == "TRADE" && compArray[1] == "OPEN") {
      action = 1;
   } else if (compArray[0] == "TRADE" && compArray[1] == "CLOSE") {
      action = 2;
   } else if (compArray[0] == "RATES") {
      action = 3;
   } else if (compArray[0] == "DATA") {
      action = 4;
   }

   switch (action) {

      case 1:
         Print("OPEN A TRADE");
         break;

      case 2: 
         Print("CLOSE A TRADE");
         break;
      
      case 3:
         Print("RATES");
         break;

      case 4: 
         Print("DATA");
         break;

      default: 
         break;

   }
}

/* Envoie d'update au client. */
void SendUpdateMessage(Socket &pSocket) {

}