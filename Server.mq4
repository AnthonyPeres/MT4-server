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
#include "Commands.mqh"

extern string ClientID = "MT4_SERVER";
extern string host = "*";
extern string protocol = "tcp";
extern int REP_PORT = 5555;
extern int PUSH_PORT = 5556;
extern int TIMER = 1

// Create ZMQ Context
Context context(ClientID); 

// Create REP Socket
Socket repSocket(context, ZMQ_REP);

// Create PUSH Socket
Socket pushSocket(context, ZMQ_PUSH);

// Message
ZmqMsg request;
uchar data[];


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // System check.
   if (!run_tests()) {
      return(INIT_FAILED);
   }

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
   // receive_request(true);
   ping_client();
}


//+------------------------------------------------------------------+
//| Other functions                                                  |
//+------------------------------------------------------------------+

void receive_request(bool nowait)
{
   repSocket.recv(request, nowait);
   ZmqMsg retour = processRequest(request);
   repSocket.send(retour);
}

ZmqMsg processRequest(ZmqMsg &request) {

   ZmqMsg reply;
   
   string components[];
   
   if (request.size() > 0) {
   
      // Get data from request
      ArrayResize(data, request.size());
      request.getData(data);
      string dataStr = CharArrayToString(data);
      
      // Process data 
      parseZmqMessage(dataStr, components);
      
      // Interpret data 
      //InterpretZmqMessage(pushSocket, components);
      
      // Construct response
      ZmqMsg ret(StringFormat("[SERVER] Processing: %s", dataStr));
      reply = ret;   
   
   } else {
   
      // No data received
   }
   
   return reply;

}





//--- Interpret ZMQ message and perform actions
void InterpretZmqMessage(Socket &pSocket, string& compArray[]) {

   
   

}



//--- Parse Zmq Message
void parseZmqMessage(string& message, string& retArray[]) {

   Print("Parsing: " + message);
   string sep = "|";
   ushort u_sep = StringGetCharacter(sep, 0);
   
   int splits = StringSplit(message, u_sep, retArray);
   
   for (int i = 0; i < splits; i++) {
   
      Print(" " + i + ")" + retArray[i]);
   
   }

}


//--- Generate string for Bid/Ask by symbol
string getBidAndAsk(string symbol) {

   double bid = MarketInfo(symbol, MODE_BID);
   double ask = MarketInfo(symbol, MODE_ASK);

   return StringFormat("%f|%f", bid, ask);

}


//--- Inform Client
void informPullClient(Socket& puSocket, string message) {

   ZmqMsg pushReply(StringFormat("%s", message));
   // pushSocket.send(pushReply, true, false);
   
   puSocket.send(pushReply, true); // NON-BLOCKING
   // pushSocket.send(pushReply, false); // BLOCKING

}


bool run_tests() {

}