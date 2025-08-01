# RemedyBot – AI-Powered Forex Signal Expert Advisor

RemedyBot is a custom-built Expert Advisor (EA) for MetaTrader 5 that uses a combination of technical indicators to analyze forex charts and provide trade signals. Designed for personal use and learning purposes, it applies logic based on:

- ✅ ZigZag Indicator
- ✅ 50 EMA (Exponential Moving Average)
- ✅ Stochastic Oscillator

---

## 📊 Strategy Logic

RemedyBot performs market analysis and trade decisions using these conditions:

1. **Buy Signal**  
   - ZigZag shows a recent low (support).
   - 50 EMA is sloping upward.
   - Stochastic indicates oversold (cross below 20 then up).

2. **Sell Signal**  
   - ZigZag shows a recent high (resistance).
   - 50 EMA is sloping downward.
   - Stochastic indicates overbought (cross above 80 then down).

3. **No Trade Conditions**  
   - ADX (Average Directional Index) is below 20 (weak trend).
   - Symbol not synchronized or indicators not loaded.

---

## 📁 File Structure

