//+------------------------------------------------------------------+
//|                Remedy Multi-Timeframe Strategy EA               |
//+------------------------------------------------------------------+
#property strict

input double   LotSize             = 0.1;
input string   TradeStartTime      = "09:00";
input string   TradeEndTime        = "17:00";
input double   StopLossBufferPips  = 5.0;
input int      ADXThreshold        = 25;
input int      MaxTradesPerDir     = 1;

double Pip() { return SymbolInfoDouble(_Symbol, SYMBOL_POINT); }
int    DigitsAdjust() { return (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS); }

//+------------------------------------------------------------------+
void OnTick()
{
   datetime now = TimeCurrent();
   datetime start = StringToTime(TimeToString(now, TIME_DATE) + " " + TradeStartTime);
   datetime end   = StringToTime(TimeToString(now, TIME_DATE) + " " + TradeEndTime);
   if(now < start || now > end) return;

   if(CountOpenTrades(ORDER_TYPE_BUY) < MaxTradesPerDir && CheckBuySignal())
      PlaceOrder(ORDER_TYPE_BUY);

   if(CountOpenTrades(ORDER_TYPE_SELL) < MaxTradesPerDir && CheckSellSignal())
      PlaceOrder(ORDER_TYPE_SELL);
}

//+------------------------------------------------------------------+
int CountOpenTrades(int type)
{
   int count = 0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
         if((int)PositionGetInteger(POSITION_TYPE)==type) count++;
   }
   return count;
}

//+------------------------------------------------------------------+
bool CheckBuySignal()
{
   if(!CheckADX(PERIOD_D1, ADXThreshold)) return false;

   if(IsBullishD1() &&
      IsValidH4(true) &&
      IsValidH1(true) &&
      IsValidM30(true) &&
      IsValidM15(true) &&
      IsStoch(PERIOD_M5, true))
      return true;

   return false;
}

bool CheckSellSignal()
{
   if(!CheckADX(PERIOD_D1, ADXThreshold)) return false;

   if(IsBearishD1() &&
      IsValidH4(false) &&
      IsValidH1(false) &&
      IsValidM30(false) &&
      IsValidM15(false) &&
      IsStoch(PERIOD_M5, false))
      return true;

   return false;
}

//+------------------------------------------------------------------+
bool IsBullishD1()
{
   return IsStoch(PERIOD_D1, true) && IsTwoCandlesBullish(PERIOD_D1);
}

bool IsBearishD1()
{
   return IsStoch(PERIOD_D1, false) && IsTwoCandlesBearish(PERIOD_D1);
}

bool IsValidH4(bool buy)
{
   if(!IsStoch(PERIOD_H4, buy)) return false;
   double zz = GetZigZag(buy, PERIOD_H4);
   double price = SymbolInfoDouble(_Symbol, buy ? SYMBOL_BID : SYMBOL_ASK);
   if(buy && price <= zz) return false;
   if(!buy && price >= zz) return false;
   return true;
}

bool IsValidH1(bool buy)
{
   if(!IsStochRange(PERIOD_H1, buy)) return false;
   double zz = GetZigZag(buy, PERIOD_H1);
   double price = SymbolInfoDouble(_Symbol, buy ? SYMBOL_BID : SYMBOL_ASK);
   if(MathAbs(price-zz) > 10*Pip()) return false;
   return true;
}

bool IsValidM30(bool buy)
{
   if(!IsStoch(PERIOD_M30, buy)) return false;
   double zz = GetZigZag(buy, PERIOD_M30);
   double price = SymbolInfoDouble(_Symbol, buy ? SYMBOL_BID : SYMBOL_ASK);
   if(MathAbs(price-zz) > 10*Pip()) return false;
   return true;
}

bool IsValidM15(bool buy)
{
   if(!IsStoch(PERIOD_M15, buy)) return false;
   double zz = GetZigZag(!buy, PERIOD_M30);
   double price = SymbolInfoDouble(_Symbol, buy ? SYMBOL_BID : SYMBOL_ASK);
   if(buy && price <= zz) return false;
   if(!buy && price >= zz) return false;
   return true;
}

//+------------------------------------------------------------------+
bool IsTwoCandlesBullish(ENUM_TIMEFRAMES tf)
{
   double o1=iOpen(_Symbol,tf,1), c1=iClose(_Symbol,tf,1);
   double o2=iOpen(_Symbol,tf,2), c2=iClose(_Symbol,tf,2);
   return (c1>o1 && c2>o2);
}

bool IsTwoCandlesBearish(ENUM_TIMEFRAMES tf)
{
   double o1=iOpen(_Symbol,tf,1), c1=iClose(_Symbol,tf,1);
   double o2=iOpen(_Symbol,tf,2), c2=iClose(_Symbol,tf,2);
   return (c1<o1 && c2<o2);
}

bool IsStoch(ENUM_TIMEFRAMES tf, bool buy)
{
   int handle = iStochastic(_Symbol, tf, 5,3,3,MODE_SMA,STO_LOWHIGH);
   double stoch[];
   ArraySetAsSeries(stoch,true);
   CopyBuffer(handle,0,0,1,stoch);
   double k = stoch[0];
   IndicatorRelease(handle);
   return (buy && k<20) || (!buy && k>80);
}

bool IsStochRange(ENUM_TIMEFRAMES tf, bool buy)
{
   int handle = iStochastic(_Symbol, tf, 5,3,3,MODE_SMA,STO_LOWHIGH);
   double stoch[];
   ArraySetAsSeries(stoch,true);
   CopyBuffer(handle,0,0,1,stoch);
   double k = stoch[0];
   IndicatorRelease(handle);
   if(buy) return (k>=10 && k<=20);
   else return (k>=80 && k<=90);
}

bool CheckADX(ENUM_TIMEFRAMES tf, int threshold)
{
   int handle = iADX(_Symbol,tf,14);
   double adx[];
   ArraySetAsSeries(adx,true);
   CopyBuffer(handle,0,0,1,adx);
   double val = adx[0];
   IndicatorRelease(handle);
   return (val>=threshold);
}

//+------------------------------------------------------------------+
double GetZigZag(bool low, ENUM_TIMEFRAMES tf)
{
   int zzHandle = iCustom(_Symbol, tf, "ZigZag", 12,5,3);
   double zzBuffer[];
   ArraySetAsSeries(zzBuffer,true);
   CopyBuffer(zzHandle,0,0,20,zzBuffer);

   for(int i=1; i<20; i++) {
      if(zzBuffer[i]!=0.0) {
         IndicatorRelease(zzHandle);
         return zzBuffer[i];
      }
   }

   IndicatorRelease(zzHandle);
   return (low ? SymbolInfoDouble(_Symbol,SYMBOL_BID) : SymbolInfoDouble(_Symbol,SYMBOL_ASK));
}

//+------------------------------------------------------------------+
void PlaceOrder(int direction)
{
   double price = (direction==ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol,SYMBOL_ASK) : SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double sl,tp;
   double zz_m15 = GetZigZag(direction==ORDER_TYPE_BUY,PERIOD_M15);
   double zz_m30 = GetZigZag(direction!=ORDER_TYPE_BUY,PERIOD_M30);

   if(direction==ORDER_TYPE_BUY)
   {
      sl = zz_m15 - StopLossBufferPips*Pip();
      tp = zz_m30;
   }
   else
   {
      sl = zz_m15 + StopLossBufferPips*Pip();
      tp = zz_m30;
   }

   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action   = TRADE_ACTION_DEAL;
   request.symbol   = _Symbol;
   request.volume   = LotSize;
   request.type     = (ENUM_ORDER_TYPE)direction;
   request.price    = price;
   request.sl       = NormalizeDouble(sl,DigitsAdjust());
   request.tp       = NormalizeDouble(tp,DigitsAdjust());
   request.deviation= 10;
   request.magic    = 987654;
   request.type_filling = ORDER_FILLING_IOC;

   if(!OrderSend(request,result))
      Print("OrderSend failed: ",GetLastError());
   else
      Print("Trade placed: Ticket #",result.order);
}

//+------------------------------------------------------------------+
