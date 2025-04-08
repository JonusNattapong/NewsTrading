//+------------------------------------------------------------------+
//|                                          NewsTrading_Config.mqh |
//|                                          Copyright 2025, JonusNattapong |
//|                                         https://github.com/JonusNattapong |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, JonusNattapong"
#property link      "https://github.com/JonusNattapong"

// Magic number for identifying EA trades
#define EXPERT_MAGIC 123456

// News impact levels
enum ENUM_NEWS_IMPACT
{
   NONE,       // No impact
   LOW,        // Low impact
   MEDIUM,     // Medium impact
   HIGH        // High impact
};

// Breakout direction
enum ENUM_BREAKOUT_DIRECTION
{
   NO_BREAKOUT,   // No breakout detected
   BREAKOUT_UP,   // Bullish breakout
   BREAKOUT_DOWN  // Bearish breakout
};

// Breakout strategy
enum ENUM_BREAKOUT_STRATEGY
{
   IMMEDIATE_AFTER_NEWS,  // Enter immediately after news release if breakout detected
   AFTER_CONFIRMATION     // Wait for candle confirmation before entering
};

// Trading times
struct TradingHours
{
   int StartHour;    // Trading session start hour
   int StartMinute;  // Trading session start minute
   int EndHour;      // Trading session end hour
   int EndMinute;    // Trading session end minute
};

// Global settings
bool AllowMultiplePositions = false;  // Allow multiple positions from different news events

// News Keywords for pattern matching
string[] NFP_KEYWORDS = {
   "Non-Farm", "Nonfarm", "NFP", "Payroll", "Employment Change"
};

string[] FOMC_KEYWORDS = {
   "FOMC", "Federal Open Market Committee", "Federal Reserve", "Interest Rate Decision",
   "Fed", "Rate Decision", "Powell"
};

string[] CPI_KEYWORDS = {
   "CPI", "Consumer Price Index", "Inflation"
};

string[] GDP_KEYWORDS = {
   "GDP", "Gross Domestic Product", "Economic Growth"
};

// Major currency pairs to trade on news
string[] MAJOR_PAIRS = {
   "EURUSD", "USDJPY", "GBPUSD", "USDCHF", "USDCAD", "AUDUSD", "NZDUSD"
};

// Maximum allowed spread during news trading (in points)
int MaxAllowedSpread = 50;

// News source URLs (for demonstration purposes)
string EconomicCalendarURL = "https://www.forexfactory.com/calendar";

// Trading session times (default to standard Forex market hours)
TradingHours SessionHours = {0, 0, 23, 59};  // 24 hours by default

// News Window - How many days to look ahead for news
int NewsLookAheadDays = 5;