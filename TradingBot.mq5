#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/OrderInfo.mqh>

double balance;
double equity;
double profit;

class My_Trade {
   public:
      string symbol;
      CTrade trade;
      CPositionInfo position_info;
      COrderInfo order_info;
      double ask;
      double bid;
      int rsi;
      double rsi_value;
      int mfi;
      double mfi_value;
      int ma14;
      double ma14_value;
      int ma50;
      double ma50_value;
      int ma100;
      double ma100_value;
      int ma9600;
      double ma9600_value;
      int position_number;
      string rsi_signal;
      string previous_rsi_signal;
      string mfi_signal;
      string previous_mfi_signal;
      string ma_signal;
      
      My_Trade::My_Trade(string my_symbol) {
         symbol = my_symbol;
         rsi = iRSI(symbol,NULL,14,PRICE_CLOSE);
         mfi = iMFI(symbol,NULL,14,VOLUME_TICK);
         ma14 = iMA(symbol,NULL,14,0,MODE_SMA,PRICE_CLOSE);
         ma50 = iMA(symbol,NULL,50,0,MODE_SMA,PRICE_CLOSE);
         ma100 = iMA(symbol,NULL,100,0,MODE_SMA,PRICE_CLOSE);
         ma9600 = iMA(symbol,NULL,9600,0,MODE_SMA,PRICE_CLOSE);
         position_number = 0;
         rsi_signal = "";
         previous_rsi_signal = "";
         mfi_signal = "";
         previous_mfi_signal = "";
         ma_signal = "";
      }
      
      void update_ask_bid() {
         ask = SymbolInfoDouble(symbol,SYMBOL_ASK);
         bid = SymbolInfoDouble(symbol,SYMBOL_BID);
      }
      
      void buy(double volume) {
         trade.Buy(volume,symbol,ask,0,0,NULL);
      }
      
      void sell(double volume) {
         trade.Sell(volume,symbol,bid,0,0,NULL);
      }
      
      void get_rsi_value() {
         double rsi_list[];
         ArraySetAsSeries(rsi_list,true);
         CopyBuffer(rsi,0,0,3,rsi_list);
         rsi_value = rsi_list[0];
      }
      
      void get_mfi_value() {
         double mfi_list[];
         ArraySetAsSeries(mfi_list,true);
         CopyBuffer(mfi,0,0,3,mfi_list);
         mfi_value = mfi_list[0];
      }
      
      void get_rsi_signal() {
         get_rsi_value();
         
         if(previous_rsi_signal == "") {
            if(rsi_value <= 30) {
               rsi_signal = "BUY";
               previous_rsi_signal = "BUY";
            } else if(rsi_value >= 70) {
               rsi_signal = "SELL";
               previous_rsi_signal = "SELL";
              }
         } else if(previous_rsi_signal == "BUY" && rsi_value >= 40) {
            previous_rsi_signal = "";
         } else if(previous_rsi_signal == "SELL" && rsi_value <=60) {
            previous_rsi_signal = "";
         }
      }
      
      void get_mfi_signal() {
         get_mfi_value();
         
         if(previous_mfi_signal == "") {
            if(mfi_value <= 20) {
               mfi_signal = "BUY";
               previous_mfi_signal = "BUY";
            } else if(mfi_value >= 80) {
               mfi_signal = "SELL";
               previous_mfi_signal = "SELL";
            }
         } else if(previous_mfi_signal == "BUY" && mfi_value >= 30) {
            previous_mfi_signal = "";
         } else if(previous_mfi_signal == "SELL" && mfi_value <= 70) {
            previous_mfi_signal = "";
         }
      }
      
      void get_ma_values() {
         double ma14_list[];
         double ma50_list[];
         double ma100_list[];
         double ma9600_list[];
         ArraySetAsSeries(ma14_list,true);
         ArraySetAsSeries(ma50_list,true);
         ArraySetAsSeries(ma100_list,true);
         ArraySetAsSeries(ma9600_list,true);
         CopyBuffer(ma14,0,0,3,ma14_list);
         CopyBuffer(ma50,0,0,3,ma50_list);
         CopyBuffer(ma100,0,0,3,ma100_list);
         CopyBuffer(ma9600,0,0,3,ma9600_list);
         ma14_value = ma14_list[0];
         ma50_value = ma50_list[0];
         ma100_value = ma100_list[0];
         ma9600_value = ma9600_list[0];
      }
      
      void get_ma_signal() {
         get_ma_values();
         
         if((ma14_value > ma50_value) && (ask > ma100_value) && (ask > ma14_value) && (ask > ma9600_value)) {
            ma_signal = "BUY";
         } else if((ma50_value > ma14_value) && (ma100_value > bid) && (ma14_value > bid) && (ma9600_value > bid)) {
            ma_signal = "SELL";
         } else {
            ma_signal = "";
         }
      }
      
      void position_close() {
         for(int i = 0; i<PositionsTotal(); i++) {
            ulong ticket = PositionGetTicket(i);
            position_info.SelectByTicket(ticket);
            if(position_info.Profit() >= 5 || position_info.Profit() <= -50) {
               if(position_info.Symbol() == "EURUSD") {
                  eurusd.position_number--;
               } else if(position_info.Symbol() == "GBPUSD"){
                  gbpusd.position_number--;
               } else if(position_info.Symbol() == "USDJPY"){
                  USDJPY.position_number--;
               }
               trade.PositionClose(ticket);
            }
         }
      }
      
      void trade_signal() {
         update_ask_bid();
         get_rsi_signal();
         get_mfi_signal();
         get_ma_signal();
         
         if(position_number < 1) {
            if(rsi_signal == "BUY" && mfi_signal == "BUY" && ma_signal == "BUY") {
               Print(2);
               buy(0.01);
               position_number++;
               rsi_signal = "";
               mfi_signal = "";
               ma_signal = "";
            } else if(rsi_signal == "SELL" && mfi_signal == "SELL" && ma_signal == "SELL") {
               sell(0.01);
               position_number++;
               rsi_signal = "";
               mfi_signal = "";
               ma_signal = "";
            }
         }
         position_close();
      }
};

My_Trade *eurusd;
My_Trade *gbpusd;
My_Trade *USDJPY;

int OnInit() {
   eurusd = new My_Trade("EURUSD");
   gbpusd = new My_Trade("GBPUSD");
   USDJPY = new My_Trade("USDJPY");  
   
   balance = AccountInfoDouble(ACCOUNT_BALANCE);
   equity = AccountInfoDouble(ACCOUNT_EQUITY);
   profit = AccountInfoDouble(ACCOUNT_PROFIT);
   return(INIT_SUCCEEDED);
}

void OnTick() {
   balance = AccountInfoDouble(ACCOUNT_BALANCE);
   equity = AccountInfoDouble(ACCOUNT_EQUITY);
   profit = AccountInfoDouble(ACCOUNT_PROFIT);

   eurusd.trade_signal();
   gbpusd.trade_signal();
   USDJPY.trade_signal();
   
   Comment("EURUSD position number: " + DoubleToString(eurusd.position_number) + "\n" +
           "GBPUSD position number: " + DoubleToString(gbpusd.position_number) + "\n" +
           "USDJPY position number: " + DoubleToString(USDJPY.position_number) + "\n" 
   );
}