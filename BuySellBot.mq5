//+------------------------------------------------------------------+
//|                                         BuySellBot.mq5           |
//+------------------------------------------------------------------+
#property strict

input string TradeStartTime   = "08:00";
input string TradeEndTime     = "18:00";
input double LotSize          = 0.1;
input int MaxTradesPerSignal  = 1;
input double StopLossBufferPips = 0;
input double TakeProfitPips   = 40;  // TP in pips
input double StopLossPips     = 10;  // SL in pips

int tradesThisSignal = 0;

int OnInit() { return INIT_SUCCEEDED; }

void OnTick()
{
   static datetime lastM30Check = 0;
   datetime m30Time = iTime(_Symbol, PERIOD_M30, 0);
   if (m30Time == lastM30Check) return; 
   lastM30Check = m30Time;

   if (!IsTradingTime()) return;
   if (tradesThisSignal >= MaxTradesPerSignal) return;

   bool buySignal  = CheckBuySignal();
   bool sellSignal = CheckSellSignal();

   if (buySignal)
   {
      if (OpenTrade(ORDER_TYPE_BUY))
         tradesThisSignal++;
   }
   else if (sellSignal)
   {
      if (OpenTrade(ORDER_TYPE_SELL))
         tradesThisSignal++;
   }
   else
   {
      tradesThisSignal = 0;
   }
}

bool IsTradingTime()
{
   string nowStr = TimeToString(TimeCurrent(), TIME_MINUTES);
   if (nowStr >= TradeStartTime && nowStr <= TradeEndTime) return true;
   return false;
}

bool CheckBuySignal()
{
   if (!CheckM30(true)) return false;
   if (!CheckM5(true)) return false;
   return true;
}

bool CheckSellSignal()
{
   if (!CheckM30(false)) return false;
   if (!CheckM5(false)) return false;
   return true;
}

bool CheckM30(bool isBuy)
{
   int stochHandle = iStochastic(_Symbol, PERIOD_M30, 5,3,3,MODE_SMA,STO_LOWHIGH);
   double k[], d[];
   CopyBuffer(stochHandle, 0, 0, 1, k);
   CopyBuffer(stochHandle, 1, 0, 1, d);
   IndicatorRelease(stochHandle);

   if (isBuy && k[0] > 20) return false;
   if (!isBuy && k[0] < 80) return false;

   double zz[];
   int zzHandle = iCustom(_Symbol, PERIOD_M30, "Examples\\ZigZag", 12,5,3);
   int copied = CopyBuffer(zzHandle,0,0,20,zz);
   IndicatorRelease(zzHandle);

   double prevHigh=0, lastHigh=0, prevLow=0, lastLow=0;
   for(int i=1;i<copied;i++)
   {
      if(zz[i]!=0)
      {
         if(zz[i]>zz[i-1]) { prevHigh=lastHigh; lastHigh=zz[i]; }
         if(zz[i]<zz[i-1]) { prevLow=lastLow; lastLow=zz[i]; }
      }
   }

   double price = iClose(_Symbol, PERIOD_M30, 0);

   if (isBuy)
   {
      if (lastHigh <= prevHigh) return false;
      if (price < prevLow) return false;
   }
   else
   {
      if (lastLow >= prevLow) return false;
      if (price > prevHigh) return false;
   }

   return true;
}

bool CheckM5(bool isBuy)
{
   int stochHandle = iStochastic(_Symbol, PERIOD_M5, 5,3,3,MODE_SMA,STO_LOWHIGH);
   double k[], d[];
   CopyBuffer(stochHandle, 0, 0, 1, k);
   CopyBuffer(stochHandle, 1, 0, 1, d);
   IndicatorRelease(stochHandle);

   if (isBuy && k[0] > 20) return false;
   if (!isBuy && k[0] < 80) return false;

   return true;
}

bool OpenTrade(ENUM_ORDER_TYPE orderType)
{
   double sl=0,tp=0,price=0;
   double totalSL = StopLossPips + StopLossBufferPips;

   if(orderType==ORDER_TYPE_BUY)
   {
      price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      sl = price - totalSL*_Point;
      tp = price + TakeProfitPips*_Point;
   }
   else
   {
      price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      sl = price + totalSL*_Point;
      tp = price - TakeProfitPips*_Point;
   }

   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action   = TRADE_ACTION_DEAL;
   request.symbol   = _Symbol;
   request.volume   = LotSize;
   request.type     = orderType;
   request.price    = price;
   request.sl       = sl;
   request.tp       = tp;
   request.deviation= 10;
   request.type_filling = ORDER_FILLING_IOC;

   if(!OrderSend(request, result))
   {
      Print("OrderSend failed. retcode=", result.retcode);
      return false;
   }

   if(result.retcode==TRADE_RETCODE_DONE || result.retcode==TRADE_RETCODE_PLACED)
   {
      Print("Trade opened: Ticket#", result.order, " Price:", price);
      return true;
   }
   else
   {
      Print("Trade failed. Retcode=", result.retcode);
      return false;
   }
}
