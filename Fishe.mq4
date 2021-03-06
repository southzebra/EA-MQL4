//+------------------------------------------------------------------+
//|            Fishe.mq4                                             |
//|       像钓鱼一样有耐心，同时像外汇新人一样对市场保持敬畏之心     |
//|                         Copyright 2020, Another 448036253@qq.com |
//|                                                 448036253@qq.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Another 448036253@qq.com"
#property link      "448036253@qq.com"
#property version   "1.00"
#property description "静待鱼儿上钩"
#property strict
#property indicator_chart_window

#define X_OFFSET 300
#define Y_START 40
#define Y_GAP 20

input int FastMaPeriod = 10;    // 快速均线周期
input int SlowMaPeriod = 60;    // 慢速均线周期

// 指标数据结构体
struct Indicator 
{    
    // 前一个收盘的快均线、慢均线
    double maFst;
    double maSlw;
    // 更前一个收盘的快均线、慢均线
    double maFstPre;
    double maSlwPre;  
    // 多头做多信号
    bool isBuySignal;
    // 空头做空信号
    bool isSellSignal;
    
    double macdBigMain;
    double macdBigSignal;
};


MqlRates dayRates[2];

int timeOfferset = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    EventSetTimer(1);
    //创建对象
    ObjectCreate(0,"lblTimer",OBJ_LABEL,0,NULL,NULL);
    ObjectCreate(0,"lblTrend",OBJ_LABEL,0,NULL,NULL);
    ObjectCreate(0,"lblTradeSignal",OBJ_LABEL,0,NULL,NULL);
    ObjectCreate(0,"lblAvailable",OBJ_LABEL,0,NULL,NULL);
    ObjectCreate(0,"lblAuthor",OBJ_LABEL,0,NULL,NULL);
    //设置内容
    ObjectSetString(0,"lblTimer",OBJPROP_TEXT,_Symbol+"蜡烛剩余");
    ObjectSetString(0,"lblTrend",OBJPROP_TEXT,"MACD判断");
    ObjectSetString(0,"lblTradeSignal",OBJPROP_TEXT,"交易信号");
    ObjectSetString(0,"lblAvailable",OBJPROP_TEXT,"可用仓位");
    ObjectSetString(0,"lblAuthor",OBJPROP_TEXT,"作者：Another");
    //设置颜色
    ObjectSetInteger(0,"lblTimer",OBJPROP_COLOR,clrLimeGreen);
    ObjectSetInteger(0,"lblTrend",OBJPROP_COLOR,clrRed);
    ObjectSetInteger(0,"lblTradeSignal",OBJPROP_COLOR,clrGold);
    ObjectSetInteger(0,"lblAvailable",OBJPROP_COLOR,clrDeepSkyBlue);
    ObjectSetInteger(0,"lblAuthor",OBJPROP_COLOR,clrGray);
    //--- 定位右上角 
    ObjectSetInteger(0,"lblTimer",OBJPROP_CORNER ,CORNER_RIGHT_UPPER); 
    ObjectSetInteger(0,"lblTrend",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
    ObjectSetInteger(0,"lblTradeSignal",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
    ObjectSetInteger(0,"lblAvailable",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
    ObjectSetInteger(0,"lblAuthor",OBJPROP_CORNER,CORNER_RIGHT_UPPER);
    //--- 定位右下角
    //ObjectSetInteger(0,"lblAdvice",OBJPROP_CORNER,CORNER_RIGHT_LOWER);
    //设置XY坐标
    ObjectSetInteger(0,"lblTimer",OBJPROP_XDISTANCE,X_OFFSET);    
    ObjectSetInteger(0,"lblTimer",OBJPROP_YDISTANCE,Y_START);
    ObjectSetInteger(0,"lblTrend",OBJPROP_XDISTANCE,X_OFFSET);  
    ObjectSetInteger(0,"lblTrend",OBJPROP_YDISTANCE,Y_START+Y_GAP);
    ObjectSetInteger(0,"lblTradeSignal",OBJPROP_XDISTANCE,X_OFFSET);
    ObjectSetInteger(0,"lblTradeSignal",OBJPROP_YDISTANCE,Y_START+Y_GAP*2);
    ObjectSetInteger(0,"lblAvailable",OBJPROP_XDISTANCE,X_OFFSET);
    ObjectSetInteger(0,"lblAvailable",OBJPROP_YDISTANCE,Y_START+Y_GAP*3);
    ObjectSetInteger(0,"lblAuthor",OBJPROP_XDISTANCE,X_OFFSET);
    ObjectSetInteger(0,"lblAuthor",OBJPROP_YDISTANCE,Y_START+Y_GAP*4);
     
     // 据观察，黄金，原油等图标画出来的线像右边偏移了一个小时
    if(_Symbol=="XAUUSD"||_Symbol=="XTIUSD")timeOfferset = 60*60;
    // 日线轴心//画线时，时间往前移1小时(60秒*60分)
    CopyRates(_Symbol,PERIOD_D1,0,2,dayRates);
    
    //日线PP
    ObjectCreate(0,"lnDayPP",OBJ_TREND,0,dayRates[1].time+timeOfferset,dayRates[0].close,Time[0],dayRates[0].close);
    ObjectSetInteger(0,"lnDayPP",OBJPROP_COLOR,clrRed);
    ObjectSetInteger(0,"lnDayPP",OBJPROP_STYLE,STYLE_SOLID);
    ObjectSetInteger(0,"lnDayPP",OBJPROP_WIDTH,1);
    //日线S1
    ObjectCreate(0,"lnDayS1",OBJ_TREND,0,dayRates[1].time+timeOfferset,dayRates[0].close,Time[0],dayRates[0].close);
    ObjectSetInteger(0,"lnDayS1",OBJPROP_COLOR,clrRed);
    ObjectSetInteger(0,"lnDayS1",OBJPROP_STYLE,STYLE_DOT);
    ObjectSetInteger(0,"lnDayS1",OBJPROP_WIDTH,1);
    //日线R1
    ObjectCreate(0,"lnDayR1",OBJ_TREND,0,dayRates[1].time+timeOfferset,dayRates[0].close,Time[0],dayRates[0].close);
    ObjectSetInteger(0,"lnDayR1",OBJPROP_COLOR,clrRed);
    ObjectSetInteger(0,"lnDayR1",OBJPROP_STYLE,STYLE_DOT);
    ObjectSetInteger(0,"lnDayR1",OBJPROP_WIDTH,1);
    
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    // 指标计算
    Indicator ind = CalcInd();
    
    // 枢轴线
    PP();
    
    // 指标解读
    Analyze(ind);
    
    // 风险提示
    Risk();
    
    return(rates_total);
}
  
//+------------------------------------------------------------------+
//| 计时器时间                                                       |
//+------------------------------------------------------------------+
void OnTimer()
{
    // 定时刷新计算当前蜡烛剩余时间
    long hour = Time[0] + 60 * Period() - TimeCurrent();
    long minute = (hour - hour % 60) / 60;
    long second = hour % 60;
    ObjectSetString(0,"lblTimer",OBJPROP_TEXT,StringFormat("%s蜡烛剩余：%d分%d秒",_Symbol,minute,second));
}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| 指标计算                                                         |
//+------------------------------------------------------------------+
Indicator CalcInd()
{
    Indicator ind;    
    // 趋势周期的收盘快慢均线
    ind.maFst = iMA(_Symbol,_Period,FastMaPeriod,0,MODE_SMA,PRICE_CLOSE,1);
    ind.maSlw = iMA(_Symbol,_Period,SlowMaPeriod,0,MODE_SMA,PRICE_CLOSE,1);
    // 趋势周期的收盘快慢均线
    ind.maFstPre = iMA(_Symbol,_Period,FastMaPeriod,0,MODE_SMA,PRICE_CLOSE,2);
    ind.maSlwPre = iMA(_Symbol,_Period,SlowMaPeriod,0,MODE_SMA,PRICE_CLOSE,2); 
    
    //MACD主要，大周期
    ind.macdBigMain = iMACD(_Symbol,PERIOD_H4,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
    //MACD信号，大周期
    ind.macdBigSignal = iMACD(_Symbol,PERIOD_H4,12,26,9,PRICE_CLOSE,MODE_SIGNAL,1);
    
    // 金叉信号
    if(ind.maFstPre<ind.maSlwPre && ind.maFst>ind.maSlw){
        ind.isBuySignal = true;
    }else{
        ind.isBuySignal = false;
    }
    // 空头信号
    if(ind.maFstPre>ind.maSlwPre && ind.maFst<ind.maSlw){
        ind.isSellSignal = true;
    }else{
        ind.isSellSignal = false;
    }
    return ind;
}

//+------------------------------------------------------------------+
//| 枢纽轴心PP                                                       |
//+------------------------------------------------------------------+
void PP()
{
    //典型： (yesterday_high + yesterday_low + yesterday_close)/3
    //给予收盘价更高权重： (yesterday_high + yesterday_low +2* yesterday_close)/4
    CopyRates(_Symbol,PERIOD_D1,0,2,dayRates);
    double dayHigh =  dayRates[0].high;
    double dayLow =  dayRates[0].low;
    double dayClose = dayRates[0].close;
    // 轴心
    double dayPP = (dayHigh + dayLow + dayClose)/3;
    // 支撑1：(2 * P) - H
    // 阻力1： (2 * P) - L
    double dayS1 = 2*dayPP - dayHigh;
    double dayR1 = 2*dayPP - dayLow;

    ObjectMove(0,"lnDayPP",0,dayRates[1].time+timeOfferset,dayPP);
    ObjectMove(0,"lnDayPP",1,Time[0],dayPP);
    ObjectMove(0,"lnDayS1",0,dayRates[1].time+timeOfferset,dayS1);
    ObjectMove(0,"lnDayS1",1,Time[0],dayS1);
    ObjectMove(0,"lnDayR1",0,dayRates[1].time+timeOfferset,dayR1);
    ObjectMove(0,"lnDayR1",1,Time[0],dayR1);
}

//+------------------------------------------------------------------+
//| 指标解读                                                         |
//+------------------------------------------------------------------+
void Analyze(const Indicator &ind)
{    
    //MACD走势判定
    //多头趋势
    if(ind.macdBigSignal>0 && ind.macdBigMain>ind.macdBigSignal)
    {
        ObjectSetString(0,"lblTrend",OBJPROP_TEXT,"4H MACD：多头↑");
    }
    else if(ind.macdBigSignal>0 && ind.macdBigMain<ind.macdBigSignal)
    {
        ObjectSetString(0,"lblTrend",OBJPROP_TEXT,"4H MACD：多头调整");
    }
    else if(ind.macdBigSignal<0 && ind.macdBigMain<ind.macdBigSignal)
    {
        ObjectSetString(0,"lblTrend",OBJPROP_TEXT,"4H MACD：空头↓");
    }
    else if(ind.macdBigSignal<0 && ind.macdBigMain>ind.macdBigSignal)
    {
        ObjectSetString(0,"lblTrend",OBJPROP_TEXT,"4H MACD：空头调整");
    }
    else
    {
        ObjectSetString(0,"lblTrend",OBJPROP_TEXT,"4H MACD：震荡~");
    }
    
    
    // 多：金叉(快均线>慢均线)，同时为了预防假突破要求形成金叉右侧的K线开盘价格在慢速均线上方
    if(ind.isBuySignal && Open[1]>ind.maSlw)
    {
        ObjectSetString(0,"lblTradeSignal",OBJPROP_TEXT,"交易信号：金叉买多");
    }    
    // 空：死叉(快均线<慢均线)，同时为了预防假突破要求形成死叉右侧的K线开盘价格在慢速均线下方
    else if(ind.isSellSignal && Open[1]<ind.maSlw)
    {
        ObjectSetString(0,"lblTradeSignal",OBJPROP_TEXT,"交易信号：死叉卖空");
    }
    else
    {
        ObjectSetString(0,"lblTradeSignal",OBJPROP_TEXT,"交易信号：暂无");
    }
}

//+------------------------------------------------------------------+
//| 风险提示                                                         |
//+------------------------------------------------------------------+
void Risk()
{
    // 仓位计算
    double balance = AccountBalance();
    double totalLots = balance / 1000.0;
    // 已持仓
    double hasLots = 0;
    for(int i=0;i<OrdersTotal();i++)
    {
        if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
            Print("注意！选中仓单失败！序号=[",i,"]");
            continue;
        }
        if(OrderType()==OP_BUY || OrderType()==OP_SELL)
        {
            if(OrderSymbol()=="XTIUSD")
            {
                hasLots += (OrderLots()/5.0);            
            }
            else
            {
                hasLots += OrderLots();
            }         
        }
    }
    
    double available = totalLots - hasLots;
    // 高风险品种仓位减半
    if(_Symbol=="XTIUSD")
    {
        available *= 2.5;
    }
    if(_Symbol=="XAUUSD")
    {
        available /= 2;
    }
    ObjectSetString(0, "lblAvailable", OBJPROP_TEXT, "可用仓位：" + DoubleToStr(available,2));
}
//+------------------------------------------------------------------+