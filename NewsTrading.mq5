//+------------------------------------------------------------------+
//|                                                  NewsTrading.mq5 |
//|                                          Copyright 2025, JonusNattapong |
//|                                         https://github.com/JonusNattapong |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, JonusNattapong"
#property link      "https://github.com/JonusNattapong"
#property version   "1.00"
#property description "News Trading Expert Advisor"
#property strict

// Include required files
#include "NewsTrading_Config.mqh"
#include "NewsTrading_Utils.mqh"

// Input parameters
input string  NewsSettings       = "==== News Trading Settings ===="; // News Settings
input bool    EnableNewsTrading  = true;                 // Enable News Trading
input ENUM_NEWS_IMPACT NewsImpact = HIGH;                // Minimum News Impact Level
input int     MinutesBeforeNews  = 15;                   // Minutes to wait before news
input int     MinutesAfterNews   = 30;                   // Minutes to wait after news
input bool    TradeNFP           = true;                 // Trade Non-Farm Payroll
input bool    TradeFOMC          = true;                 // Trade FOMC Announcements
input bool    TradeCPI           = true;                 // Trade CPI Announcements
input bool    TradeGDP           = true;                 // Trade GDP Announcements

input string  TradeSettings      = "==== Trade Settings ====";       // Trade Settings
input ENUM_BREAKOUT_STRATEGY BreakoutStrategy = AFTER_CONFIRMATION;  // Breakout Entry Strategy
input double  LotSize            = 0.1;                  // Lot Size
input int     StopLoss           = 100;                  // Stop Loss in points
input int     TakeProfit         = 200;                  // Take Profit in points
input int     BreakoutPips       = 20;                   // Breakout confirmation (pips)
input int     MaxSlippage        = 10;                   // Maximum allowed slippage in points

input string  TimeframeSettings  = "==== Timeframe Settings ====";   // Timeframe Settings
input ENUM_TIMEFRAMES AnalysisTimeframe = PERIOD_M15;    // Analysis Timeframe
input ENUM_TIMEFRAMES EntryTimeframe = PERIOD_M5;        // Entry Timeframe

input string  VolatilitySettings = "==== Volatility Settings ====";  // Volatility Settings
input bool    UseATR             = true;                 // Use ATR for SL/TP adjustment
input int     ATRPeriod          = 14;                   // ATR Period
input double  ATRMultiplier      = 2.0;                  // ATR Multiplier for SL/TP

// Global variables
int OngoingPositions = 0;
bool NewsDetected = false;
datetime NextNewsTime = 0;
string NextNewsTitle = "";
ENUM_NEWS_IMPACT NextNewsImpact = NONE;
datetime LastCheckTime = 0;
int NewsCheckInterval = 60 * 15; // 15 minutes

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   // Check if we can trade
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      PrintFormat("Trading is not allowed in the terminal");
      return INIT_FAILED;
   }
   
   // Initialize economic calendar connection
   if(EnableNewsTrading && !InitializeCalendar())
   {
      PrintFormat("Failed to initialize economic calendar");
      return INIT_FAILED;
   }
   
   // Initialize trading hours
   InitializeTradingHours();
   
   // Update upcoming news
   UpdateUpcomingNews();
   
   // Display initialization information
   PrintFormat("News Trading EA initialized successfully");
   PrintFormat("Watching for news events: NFP=%s, FOMC=%s, CPI=%s, GDP=%s", 
               TradeNFP ? "Yes" : "No", 
               TradeFOMC ? "Yes" : "No",
               TradeCPI ? "Yes" : "No",
               TradeGDP ? "Yes" : "No");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Clean up any resources
   CloseCalendarConnection();
   PrintFormat("News Trading EA deinitialized, reason code=%d", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check if news trading is enabled
   if(!EnableNewsTrading) return;
   
   // Get current time
   datetime currentTime = TimeCurrent();
   
   // Update news data if needed (every 15 minutes)
   if(currentTime - LastCheckTime > NewsCheckInterval)
   {
      UpdateUpcomingNews();
      LastCheckTime = currentTime;
   }
   
   // If no upcoming news, exit
   if(NextNewsTime == 0) return;
   
   // Calculate time difference to next news in seconds
   int secondsToNews = (int)(NextNewsTime - currentTime);
   
   // Handle pre-news period
   if(secondsToNews > 0 && secondsToNews <= MinutesBeforeNews * 60)
   {
      HandlePreNewsCondition();
      return;
   }
   
   // Handle news release and post-news period
   if(secondsToNews <= 0 && MathAbs(secondsToNews) <= MinutesAfterNews * 60)
   {
      HandleNewsReleaseCondition();
      return;
   }
   
   // Normal market condition - outside news windows
   HandleNormalMarketCondition();
}

//+------------------------------------------------------------------+
//| Handle pre-news condition                                        |
//+------------------------------------------------------------------+
void HandlePreNewsCondition()
{
   Print("In pre-news condition. ", MinutesBeforeNews, " minutes before news: ", NextNewsTitle);
   
   // Close existing trades if needed to reduce risk before news
   if(ShouldCloseTradesBeforeNews())
   {
      CloseAllTrades("Closing before high-impact news");
   }
   
   // Display notification about upcoming news
   if(!NewsDetected)
   {
      NewsDetected = true;
      string message = StringFormat("Upcoming %s news: %s at %s", 
                     GetNewsImpactString(NextNewsImpact),
                     NextNewsTitle, 
                     TimeToString(NextNewsTime, TIME_MINUTES));
      Alert(message);
   }
}

//+------------------------------------------------------------------+
//| Handle news release condition                                    |
//+------------------------------------------------------------------+
void HandleNewsReleaseCondition()
{
   // Calculate minutes after news
   int minutesAfterNews = (int)MathAbs(NextNewsTime - TimeCurrent()) / 60;
   
   Print("News has been released: ", NextNewsTitle, ", Minutes after: ", minutesAfterNews);
   
   // Check if we should trade based on this news
   if(!ShouldTradeThisNews(NextNewsTitle, NextNewsImpact))
   {
      Print("Skipping this news event as it doesn't match our criteria");
      return;
   }
   
   // Analyze market conditions after news
   if(BreakoutStrategy == IMMEDIATE_AFTER_NEWS || 
      (BreakoutStrategy == AFTER_CONFIRMATION && IsBreakoutConfirmed()))
   {
      // Detect breakout direction
      ENUM_BREAKOUT_DIRECTION direction = DetectBreakoutDirection();
      
      if(direction != NO_BREAKOUT)
      {
         // Enter trade based on breakout direction
         EnterBreakoutTrade(direction);
      }
   }
}

//+------------------------------------------------------------------+
//| Handle normal market condition (outside news windows)            |
//+------------------------------------------------------------------+
void HandleNormalMarketCondition()
{
   // Reset news detection flag when outside news window
   if(NewsDetected) NewsDetected = false;
   
   // Manage existing trades if any
   ManageExistingTrades();
}

//+------------------------------------------------------------------+
//| Detect breakout direction after news                             |
//+------------------------------------------------------------------+
ENUM_BREAKOUT_DIRECTION DetectBreakoutDirection()
{
   // Get volatility measurement using ATR
   double atr = 0;
   if(UseATR)
   {
      int atrHandle = iATR(_Symbol, AnalysisTimeframe, ATRPeriod);
      double atrBuffer[];
      ArraySetAsSeries(atrBuffer, true);
      CopyBuffer(atrHandle, 0, 0, 3, atrBuffer);
      atr = atrBuffer[0];
   }
   
   // Get recent price data
   double highBuffer[], lowBuffer[], closeBuffer[];
   ArraySetAsSeries(highBuffer, true);
   ArraySetAsSeries(lowBuffer, true);
   ArraySetAsSeries(closeBuffer, true);
   
   // Copy recent price data
   CopyHigh(_Symbol, EntryTimeframe, 0, 10, highBuffer);
   CopyLow(_Symbol, EntryTimeframe, 0, 10, lowBuffer);
   CopyClose(_Symbol, EntryTimeframe, 0, 10, closeBuffer);
   
   // Get pre-news levels
   double preNewsHigh = FindPreNewsHigh();
   double preNewsLow = FindPreNewsLow();
   
   // Current price
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   // Points to pips conversion
   double pipMultiplier = GetPipMultiplier();
   
   // Check for breakout
   if(currentPrice > preNewsHigh + BreakoutPips * pipMultiplier)
   {
      // Bullish breakout
      return BREAKOUT_UP;
   }
   else if(currentPrice < preNewsLow - BreakoutPips * pipMultiplier)
   {
      // Bearish breakout
      return BREAKOUT_DOWN;
   }
   
   return NO_BREAKOUT;
}

//+------------------------------------------------------------------+
//| Enter a trade based on breakout direction                        |
//+------------------------------------------------------------------+
void EnterBreakoutTrade(ENUM_BREAKOUT_DIRECTION direction)
{
   // Check if we already have open positions
   if(CountOpenTrades() > 0 && !AllowMultiplePositions)
   {
      Print("Already have open positions, skipping new entry");
      return;
   }
   
   // Calculate SL and TP
   double stopLoss = StopLoss * _Point;
   double takeProfit = TakeProfit * _Point;
   
   // Adjust SL and TP based on ATR if enabled
   if(UseATR)
   {
      double atr = CalculateATR(ATRPeriod);
      stopLoss = atr * ATRMultiplier;
      takeProfit = atr * ATRMultiplier * 2; // TP is twice the ATR multiplier
   }
   
   // Get trading parameters
   double tradeVolume = LotSize;
   
   // Normalize lot size
   tradeVolume = NormalizeLotSize(tradeVolume);
   
   // Calculate price levels
   double entryPrice = 0;
   double sl = 0;
   double tp = 0;
   
   ENUM_ORDER_TYPE orderType;
   string directionText;
   
   if(direction == BREAKOUT_UP)
   {
      // Buy order
      orderType = ORDER_TYPE_BUY;
      directionText = "BUY";
      entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      sl = entryPrice - stopLoss;
      tp = entryPrice + takeProfit;
   }
   else if(direction == BREAKOUT_DOWN)
   {
      // Sell order
      orderType = ORDER_TYPE_SELL;
      directionText = "SELL";
      entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      sl = entryPrice + stopLoss;
      tp = entryPrice - takeProfit;
   }
   else
   {
      // No breakout detected, exit
      return;
   }
   
   // Execute the trade
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = tradeVolume;
   request.type = orderType;
   request.price = entryPrice;
   request.sl = sl;
   request.tp = tp;
   request.deviation = MaxSlippage;
   request.magic = EXPERT_MAGIC;
   request.comment = "News Trading: " + NextNewsTitle;
   request.type_filling = ORDER_FILLING_FOK;
   
   // Send the order
   bool success = OrderSend(request, result);
   
   // Log results
   if(success && result.retcode == TRADE_RETCODE_DONE)
   {
      Print("News breakout trade executed: ", directionText, " at ", entryPrice, 
            ", SL: ", sl, ", TP: ", tp, ", Lots: ", tradeVolume);
   }
   else
   {
      Print("Error opening trade. Error code: ", result.retcode, 
            ", Description: ", GetLastErrorText(result.retcode));
   }
}

//+------------------------------------------------------------------+
//| Check if breakout is confirmed based on strategy                 |
//+------------------------------------------------------------------+
bool IsBreakoutConfirmed()
{
   // Get recent candle data
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, EntryTimeframe, 0, 3, rates);
   
   if(copied < 3) return false;
   
   // Get pre-news levels
   double preNewsHigh = FindPreNewsHigh();
   double preNewsLow = FindPreNewsLow();
   
   // Check for a strong breakout candle
   double candleRange = rates[1].high - rates[1].low;
   double averageRange = (rates[1].high - rates[1].low + rates[2].high - rates[2].low) / 2;
   double candleBody = MathAbs(rates[1].close - rates[1].open);
   
   // Breakout candle should have larger range than average
   bool isStrongCandle = (candleRange > averageRange * 1.2);
   
   // Breakout candle should have a strong body (>60% of range)
   bool isStrongBody = (candleBody > candleRange * 0.6);
   
   // Check if we have a confirmed breakout
   bool confirmedBreakout = false;
   
   // Bullish breakout
   if(rates[1].close > preNewsHigh && isStrongCandle && isStrongBody && rates[1].close > rates[1].open)
   {
      confirmedBreakout = true;
   }
   
   // Bearish breakout
   if(rates[1].close < preNewsLow && isStrongCandle && isStrongBody && rates[1].close < rates[1].open)
   {
      confirmedBreakout = true;
   }
   
   return confirmedBreakout;
}

//+------------------------------------------------------------------+
//| Update upcoming news data from economic calendar                 |
//+------------------------------------------------------------------+
void UpdateUpcomingNews()
{
   // For demonstration - in a real EA, you would connect to an economic calendar
   // service or data feed to get upcoming news events
   
   // This is a placeholder function - replace with actual implementation
   // that connects to a real economic news data source
   
   // Reset news data
   NextNewsTime = 0;
   NextNewsTitle = "";
   NextNewsImpact = NONE;
   
   // Simulate fetching upcoming news
   if(!FetchUpcomingNewsFromCalendar())
   {
      Print("Failed to fetch upcoming news from calendar");
      return;
   }
   
   // If we have upcoming news, log it
   if(NextNewsTime > 0)
   {
      Print("Next news event: ", NextNewsTitle, " at ", 
            TimeToString(NextNewsTime, TIME_DATE|TIME_MINUTES), 
            ", Impact: ", GetNewsImpactString(NextNewsImpact));
   }
}

//+------------------------------------------------------------------+
//| OnTradeTransaction Event Function                                |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                       const MqlTradeRequest& request,
                       const MqlTradeResult& result)
{
   // Handle trade events like order execution, modification, etc.
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      // Deal was added - check if it belongs to our EA
      ulong dealTicket = trans.deal;
      
      // Get deal information
      HistorySelect(TimeCurrent()-86400, TimeCurrent()+100);
      
      if(dealTicket > 0)
      {
         if(HistoryDealGetInteger(dealTicket, DEAL_MAGIC) == EXPERT_MAGIC)
         {
            // This is our deal
            long dealType = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
            double dealVolume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
            double dealPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
            
            // Log the deal
            if(dealType == DEAL_TYPE_BUY)
            {
               Print("News Trading: BUY position opened: Ticket=", dealTicket, 
                    ", Volume=", dealVolume, ", Price=", dealPrice);
            }
            else if(dealType == DEAL_TYPE_SELL)
            {
               Print("News Trading: SELL position opened: Ticket=", dealTicket, 
                    ", Volume=", dealVolume, ", Price=", dealPrice);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   // Check for upcoming news events
   UpdateUpcomingNews();
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                 const long &lparam,
                 const double &dparam,
                 const string &sparam)
{
   // Handle chart events here if needed
}