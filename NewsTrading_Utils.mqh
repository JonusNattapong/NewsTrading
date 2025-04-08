//+------------------------------------------------------------------+
//|                                          NewsTrading_Utils.mqh |
//|                                          Copyright 2025, JonusNattapong |
//|                                         https://github.com/JonusNattapong |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, JonusNattapong"
#property link      "https://github.com/JonusNattapong"

#include "NewsTrading_Config.mqh"

//+------------------------------------------------------------------+
//| Initialize connection to economic calendar                        |
//+------------------------------------------------------------------+
bool InitializeCalendar()
{
   // In a real implementation, this would connect to a news data source
   // For demonstration purposes, this returns true
   Print("Economic Calendar initialized. Using URL: ", EconomicCalendarURL);
   return true;
}

//+------------------------------------------------------------------+
//| Close connection to economic calendar                            |
//+------------------------------------------------------------------+
void CloseCalendarConnection()
{
   // Placeholder for cleaning up any connections
   Print("Economic Calendar connection closed");
}

//+------------------------------------------------------------------+
//| Initialize trading hours                                          |
//+------------------------------------------------------------------+
void InitializeTradingHours()
{
   // Set default trading hours if user hasn't specified them
   // This function could be expanded to handle different trading sessions
   Print("Trading hours initialized: ", 
         SessionHours.StartHour, ":", SessionHours.StartMinute, " - ",
         SessionHours.EndHour, ":", SessionHours.EndMinute);
}

//+------------------------------------------------------------------+
//| Check if we should close trades before high-impact news           |
//+------------------------------------------------------------------+
bool ShouldCloseTradesBeforeNews()
{
   // Check if we're approaching high-impact news
   if(NextNewsImpact >= HIGH && CountOpenTrades() > 0)
   {
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Count open trades for this EA                                    |
//+------------------------------------------------------------------+
int CountOpenTrades()
{
   int count = 0;
   
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(PositionGetTicket(i) > 0)
      {
         if(PositionGetInteger(POSITION_MAGIC) == EXPERT_MAGIC)
         {
            count++;
         }
      }
   }
   
   return count;
}

//+------------------------------------------------------------------+
//| Close all open trades                                            |
//+------------------------------------------------------------------+
void CloseAllTrades(string reason)
{
   MqlTradeRequest request;
   MqlTradeResult result;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetTicket(i) > 0)
      {
         if(PositionGetInteger(POSITION_MAGIC) == EXPERT_MAGIC)
         {
            ZeroMemory(request);
            ZeroMemory(result);
            
            request.action = TRADE_ACTION_DEAL;
            request.position = PositionGetInteger(POSITION_TICKET);
            request.symbol = PositionGetString(POSITION_SYMBOL);
            request.volume = PositionGetDouble(POSITION_VOLUME);
            request.deviation = MaxSlippage;
            request.magic = EXPERT_MAGIC;
            request.comment = reason;
            
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
               request.price = SymbolInfoDouble(request.symbol, SYMBOL_BID);
               request.type = ORDER_TYPE_SELL;
            }
            else
            {
               request.price = SymbolInfoDouble(request.symbol, SYMBOL_ASK);
               request.type = ORDER_TYPE_BUY;
            }
            
            bool success = OrderSend(request, result);
            
            if(success && result.retcode == TRADE_RETCODE_DONE)
            {
               Print("Position closed: ", request.position, ", Reason: ", reason);
            }
            else
            {
               Print("Error closing position: ", GetLastErrorText(result.retcode));
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Get error description                                            |
//+------------------------------------------------------------------+
string GetLastErrorText(int error_code)
{
   string error_string;
   
   switch(error_code)
   {
      case 0:   error_string = "No error";                                                   break;
      case 1:   error_string = "No error, trade conditions not changed";                     break;
      case 2:   error_string = "Common error";                                               break;
      case 3:   error_string = "Invalid trade parameters";                                   break;
      case 4:   error_string = "Trade server is busy";                                       break;
      case 5:   error_string = "Old version of the client terminal";                         break;
      case 6:   error_string = "No connection with trade server";                            break;
      case 7:   error_string = "Not enough rights";                                          break;
      case 8:   error_string = "Too frequent requests";                                      break;
      case 9:   error_string = "Malfunctional trade operation";                              break;
      case 64:  error_string = "Account disabled";                                           break;
      case 65:  error_string = "Invalid account";                                            break;
      case 128: error_string = "Trade timeout";                                              break;
      case 129: error_string = "Invalid price";                                              break;
      case 130: error_string = "Invalid stops";                                              break;
      case 131: error_string = "Invalid trade volume";                                       break;
      case 132: error_string = "Market is closed";                                           break;
      case 133: error_string = "Trade is disabled";                                          break;
      case 134: error_string = "Not enough money";                                           break;
      case 135: error_string = "Price changed";                                              break;
      case 136: error_string = "Off quotes";                                                 break;
      case 137: error_string = "Broker is busy";                                             break;
      case 138: error_string = "Requote";                                                    break;
      case 139: error_string = "Order is locked";                                            break;
      case 140: error_string = "Buy orders only allowed";                                    break;
      case 141: error_string = "Too many requests";                                          break;
      case 145: error_string = "Modification denied because order is too close to market";   break;
      case 146: error_string = "Trade context is busy";                                      break;
      case 147: error_string = "Expirations are denied by broker";                           break;
      case 148: error_string = "Amount of open and pending orders has reached the limit";    break;
      default:  error_string = "Unknown error " + IntegerToString(error_code);
   }
   
   return error_string;
}

//+------------------------------------------------------------------+
//| Get pip multiplier based on symbol digits                         |
//+------------------------------------------------------------------+
double GetPipMultiplier()
{
   // Get pip value based on number of digits
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   if(digits == 3 || digits == 5)
      return 0.001;  // For JPY pairs typically
   else
      return 0.0001; // For other major pairs
}

//+------------------------------------------------------------------+
//| Check if we should trade this specific news event                 |
//+------------------------------------------------------------------+
bool ShouldTradeThisNews(string newsTitle, ENUM_NEWS_IMPACT impact)
{
   // Check if impact meets our minimum requirement
   if(impact < NewsImpact)
   {
      return false;
   }
   
   // Check specific news types
   bool isNFP = false;
   bool isFOMC = false;
   bool isCPI = false;
   bool isGDP = false;
   
   // Check if this is NFP news
   for(int i = 0; i < ArraySize(NFP_KEYWORDS); i++)
   {
      if(StringFind(newsTitle, NFP_KEYWORDS[i]) >= 0)
      {
         isNFP = true;
         break;
      }
   }
   
   // Check if this is FOMC news
   for(int i = 0; i < ArraySize(FOMC_KEYWORDS); i++)
   {
      if(StringFind(newsTitle, FOMC_KEYWORDS[i]) >= 0)
      {
         isFOMC = true;
         break;
      }
   }
   
   // Check if this is CPI news
   for(int i = 0; i < ArraySize(CPI_KEYWORDS); i++)
   {
      if(StringFind(newsTitle, CPI_KEYWORDS[i]) >= 0)
      {
         isCPI = true;
         break;
      }
   }
   
   // Check if this is GDP news
   for(int i = 0; i < ArraySize(GDP_KEYWORDS); i++)
   {
      if(StringFind(newsTitle, GDP_KEYWORDS[i]) >= 0)
      {
         isGDP = true;
         break;
      }
   }
   
   // Return true only if we should trade this type of news
   return (isNFP && TradeNFP) || 
          (isFOMC && TradeFOMC) || 
          (isCPI && TradeCPI) || 
          (isGDP && TradeGDP);
}

//+------------------------------------------------------------------+
//| Get pre-news high level                                          |
//+------------------------------------------------------------------+
double FindPreNewsHigh()
{
   // Find the highest price before news release
   // Looking back a certain number of candles before news time
   
   // Calculate how many candles to look back
   int lookbackCandles = MinutesBeforeNews / PeriodSeconds(EntryTimeframe) * 60;
   if(lookbackCandles < 5) lookbackCandles = 5;
   
   // Get price data
   double highBuffer[];
   ArraySetAsSeries(highBuffer, true);
   CopyHigh(_Symbol, EntryTimeframe, 0, lookbackCandles, highBuffer);
   
   // Find the highest value
   double highestValue = 0;
   for(int i = 0; i < lookbackCandles; i++)
   {
      if(highBuffer[i] > highestValue || i == 0)
      {
         highestValue = highBuffer[i];
      }
   }
   
   return highestValue;
}

//+------------------------------------------------------------------+
//| Get pre-news low level                                           |
//+------------------------------------------------------------------+
double FindPreNewsLow()
{
   // Find the lowest price before news release
   // Looking back a certain number of candles before news time
   
   // Calculate how many candles to look back
   int lookbackCandles = MinutesBeforeNews / PeriodSeconds(EntryTimeframe) * 60;
   if(lookbackCandles < 5) lookbackCandles = 5;
   
   // Get price data
   double lowBuffer[];
   ArraySetAsSeries(lowBuffer, true);
   CopyLow(_Symbol, EntryTimeframe, 0, lookbackCandles, lowBuffer);
   
   // Find the lowest value
   double lowestValue = 999999;
   for(int i = 0; i < lookbackCandles; i++)
   {
      if(lowBuffer[i] < lowestValue || i == 0)
      {
         lowestValue = lowBuffer[i];
      }
   }
   
   return lowestValue;
}

//+------------------------------------------------------------------+
//| Calculate ATR value for volatility-based stops                   |
//+------------------------------------------------------------------+
double CalculateATR(int period)
{
   double atrValue = 0;
   
   int atrHandle = iATR(_Symbol, AnalysisTimeframe, period);
   if(atrHandle == INVALID_HANDLE)
   {
      Print("Error creating ATR indicator. Error code: ", GetLastError());
      return 0;
   }
   
   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);
   int copied = CopyBuffer(atrHandle, 0, 0, 3, atrBuffer);
   
   if(copied > 0)
   {
      atrValue = atrBuffer[0];
   }
   
   IndicatorRelease(atrHandle);
   return atrValue;
}

//+------------------------------------------------------------------+
//| Normalize lot size according to broker requirements              |
//+------------------------------------------------------------------+
double NormalizeLotSize(double volume)
{
   double minVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   // Ensure volume is within min and max
   volume = MathMax(minVolume, volume);
   volume = MathMin(maxVolume, volume);
   
   // Round to the nearest step
   volume = MathRound(volume / stepVolume) * stepVolume;
   
   return NormalizeDouble(volume, 2);
}

//+------------------------------------------------------------------+
//| Manage existing trades (trailing stops, etc)                     |
//+------------------------------------------------------------------+
void ManageExistingTrades()
{
   // This function could implement trailing stops or other
   // trade management techniques for existing positions
   
   // For now, it's a placeholder
   int trades = CountOpenTrades();
   if(trades > 0)
   {
      // Implement trade management here
   }
}

//+------------------------------------------------------------------+
//| Get news impact level as string                                  |
//+------------------------------------------------------------------+
string GetNewsImpactString(ENUM_NEWS_IMPACT impact)
{
   switch(impact)
   {
      case NONE:   return "No Impact";
      case LOW:    return "Low Impact";
      case MEDIUM: return "Medium Impact";
      case HIGH:   return "High Impact";
      default:     return "Unknown Impact";
   }
}

//+------------------------------------------------------------------+
//| Fetch upcoming news from economic calendar                       |
//+------------------------------------------------------------------+
bool FetchUpcomingNewsFromCalendar()
{
   // This is a placeholder function that would normally fetch real news data
   // from an economic calendar or other news source
   
   // For demo purposes, we'll simulate some news events
   datetime currentTime = TimeCurrent();
   
   // Simulate either NFP or FOMC news coming up in the next hour
   int newsType = MathRand() % 4;  // 0=NFP, 1=FOMC, 2=CPI, 3=GDP
   
   // Simulate news in the next 1-60 minutes
   int minutesToNews = 15 + MathRand() % 45;  // 15-60 minutes
   NextNewsTime = currentTime + minutesToNews * 60;
   
   // Set news title and impact based on type
   switch(newsType)
   {
      case 0:  // NFP
         NextNewsTitle = "US Non-Farm Payrolls";
         NextNewsImpact = HIGH;
         break;
      case 1:  // FOMC
         NextNewsTitle = "FOMC Interest Rate Decision";
         NextNewsImpact = HIGH;
         break;
      case 2:  // CPI
         NextNewsTitle = "US Consumer Price Index (CPI)";
         NextNewsImpact = MEDIUM;
         break;
      case 3:  // GDP
         NextNewsTitle = "US Gross Domestic Product (GDP)";
         NextNewsImpact = MEDIUM;
         break;
   }
   
   return true;
}