# News Trading Expert Advisor for MetaTrader 5

## Overview

This Expert Advisor (EA) is designed to automate the "News Trading" strategy for MetaTrader 5. The EA monitors economic calendars for high-impact news events such as Non-Farm Payroll (NFP), FOMC announcements, CPI, and GDP releases, and executes trades based on market breakouts that occur after these news releases.

## Key Features

- **Economic Calendar Integration**: Monitors upcoming high-impact economic news events
- **Customizable News Selection**: Choose which news types to trade (NFP, FOMC, CPI, GDP)
- **Breakout Trading Strategies**: Multiple entry strategies after news release
- **Volatility-Based Position Sizing**: Uses ATR to adjust stop loss and take profit levels
- **Risk Management**: Options to close existing trades before high-impact news
- **Pre-News Alerts**: Notifications about upcoming important news events

## Installation

1. Copy all files to your MetaTrader 5 `Experts` folder:
   - `NewsTrading.mq5`
   - `NewsTrading_Config.mqh`
   - `NewsTrading_Utils.mqh`

2. Restart MetaTrader 5 or refresh the Navigator panel

3. Drag and drop the EA onto a chart

## Configuration

### News Trading Settings

- **Enable News Trading**: Turn the news trading functionality on/off
- **Minimum News Impact Level**: Set the minimum impact level of news to trade (High, Medium, Low)
- **Minutes Before News**: Time window before news when the EA prepares for the event
- **Minutes After News**: Time window after news to look for trading opportunities
- **Trade NFP**: Enable/disable trading on Non-Farm Payroll releases
- **Trade FOMC**: Enable/disable trading on FOMC announcements
- **Trade CPI**: Enable/disable trading on CPI releases
- **Trade GDP**: Enable/disable trading on GDP releases

### Trade Settings

- **Breakout Strategy**: Choose between immediate entry or waiting for confirmation
- **Lot Size**: Size of positions to open
- **Stop Loss**: Default stop loss in points (can be overridden by ATR)
- **Take Profit**: Default take profit in points (can be overridden by ATR)
- **Breakout Pips**: Number of pips required for breakout confirmation
- **Max Slippage**: Maximum allowed slippage when entering trades

### Timeframe Settings

- **Analysis Timeframe**: Timeframe used for technical analysis (recommended: M15)
- **Entry Timeframe**: Timeframe used for entry signals (recommended: M5)

### Volatility Settings

- **Use ATR**: Enable ATR for dynamic stop loss and take profit
- **ATR Period**: Period setting for the ATR indicator
- **ATR Multiplier**: Multiplier for ATR-based stop loss calculations

## How It Works

1. The EA monitors economic calendars for upcoming news events
2. Before high-impact news, the EA can optionally close existing positions to reduce risk
3. After news release, the EA analyzes price action for breakout opportunities
4. When a valid breakout is detected, the EA opens a position in the direction of the breakout
5. Stop loss and take profit are set based on either fixed values or volatility (ATR)

## Trading Strategy

The EA implements a classic news trading approach:

1. **Pre-News Phase**: Identifies upcoming high-impact news and prepares by potentially closing existing trades
2. **News Release Phase**: Waits for the initial market reaction
3. **Breakout Detection**: Looks for strong price movements beyond pre-news levels
4. **Trade Execution**: Enters trades in the direction of the breakout with defined risk parameters

## Requirements

- MetaTrader 5 platform
- A broker that allows trading during news releases (some brokers widen spreads)
- Stable internet connection to receive news updates

## Disclaimer

This Expert Advisor involves trading during potentially volatile market conditions. Always test thoroughly on a demo account before using with real funds. News trading carries significant risk due to increased volatility, widened spreads, and potential slippage.

## License

Copyright (c) 2025, [Your Name]
All rights reserved.