//+------------------------------------------------------------------+
//|                                                     SD_Order.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright ">>K线突破策略-EA<<"
#property link        "#"
#property copyright   "#←"
#property strict



input string             _名称_="K线突破策略-EA";

input int                识别码  =8888;  

extern  ENUM_TIMEFRAMES  判断时间=0  ;
input int                大量K线实体小于=500;
input int                大量K线影线小于=500;
input int                大量K线区间修正=50;
input double             首单手数       =0.01;
input double             损单开仓倍数   =1;
input int                区间固定止盈   =50;
input double             区间止盈倍数   =2;
input int                距离止盈线距离激活盈保=50;
input int                盈保点数       =50;
input bool               强平开关      =false;
input string             每天强平时间   ="23:00:00";
input int                新高新低修正点数    =20;
input int                新高新低单固定止盈=300;
input int                新高新低单固定止损=300;


datetime  QJ_TIME=0; //区间时间

double    QJ_HIGH; //区间高点
double    QJ_LOW;  //区间低点

double    mTick[2];

int OnInit()
{
   mTick[0]=Close[0];
   mTick[1]=Close[0];
   return(INIT_SUCCEEDED);
}
void OnTick()
{
    mTick[1]=mTick[0];
    mTick[0]=Close[0];
    
    My_GetMaxVolK();//计算做单区间
    
    if(QJ_TIME==0)return;
    
    double   DayHigh=0;
    double   DayLow =0;
    int      di  =1;
    
    MdOrder();//盈保功能
  
    if(TimeDayOfWeek(iTime(Symbol(),判断时间,di))>=1 && TimeDayOfWeek(iTime(Symbol(),判断时间,di))<=5)
    {
        di=1;
    }else
    {
        di=2;
    }
    
    
    My_HighLine(iHigh(Symbol(),判断时间,di)+新高新低修正点数*Point);
    My_LowLine (iLow(Symbol() ,判断时间,di)-新高新低修正点数*Point);
    
    My_SetRectangle(QJ_TIME);
    
    
    datetime pctime=StringToTime(TimeToStr(TimeCurrent(),TIME_DATE) +" "+每天强平时间);
    
    if(强平开关 && TimeCurrent()>pctime) {PingCang();return;}
    
    

    if(QJ_HIGH!=0 && QJ_LOW!=0 && QJ_HIGH>QJ_LOW && my_GetOrderCount(TimeToStr(QJ_TIME,TIME_DATE|TIME_MINUTES))==0&&my_GetLSOrderCount(TimeToStr(QJ_TIME,TIME_DATE|TIME_MINUTES))<2&&my_GetLastYingLi(TimeToStr(QJ_TIME,TIME_DATE|TIME_MINUTES))<=0)
      {
          if(mTick[1]<=QJ_HIGH && mTick[0]>QJ_HIGH)
          {
             double lot=首单手数; 
             
             if(my_GetLastYingLi(TimeToStr(QJ_TIME,TIME_DATE|TIME_MINUTES))<0)  lot = 首单手数*损单开仓倍数;
             
             if(区间固定止盈>0)
             {
             
                KaiCang(OP_BUY,lot,mTick[0]+区间固定止盈*Point,QJ_LOW,TimeToStr(QJ_TIME,TIME_DATE|TIME_MINUTES));
             }else
             {
                KaiCang(OP_BUY,lot,mTick[0]+(QJ_HIGH-QJ_LOW)*区间止盈倍数,QJ_LOW,TimeToStr(QJ_TIME,TIME_DATE|TIME_MINUTES));
             }
             return;
          }
          if(mTick[1]>=QJ_LOW && mTick[0]<QJ_LOW)
          {
             double lot=首单手数;  
             if(my_GetLastYingLi(TimeToStr(QJ_TIME,TIME_DATE|TIME_MINUTES))<0) lot=首单手数*损单开仓倍数;
             
             if(区间固定止盈>0)
             {
                   KaiCang(OP_SELL,lot,mTick[0]-区间固定止盈*Point,QJ_HIGH,TimeToStr(QJ_TIME,TIME_DATE|TIME_MINUTES));
             }else
             {
                  KaiCang(OP_SELL,lot,mTick[0]-(QJ_HIGH-QJ_LOW)*区间止盈倍数,QJ_HIGH,TimeToStr(QJ_TIME,TIME_DATE|TIME_MINUTES)); 
             }
            
             return;
          }
      } 
      
      
      if(mTick[0]>iHigh(Symbol(),判断时间,di)+新高新低修正点数*Point &&  my_GetHLCount("HL"+TimeToStr(iTime(Symbol(),判断时间,di),TIME_DATE))==0)
      {
             KaiCang(OP_BUY,首单手数,mTick[0]+新高新低单固定止盈*Point,mTick[0]-新高新低单固定止损*Point,"HL"+TimeToStr(iTime(Symbol(),判断时间,di),TIME_DATE));
             return;
      }
      if(mTick[0]<iLow(Symbol(),判断时间,1)-新高新低修正点数*Point   &&  my_GetHLCount("HL"+TimeToStr(iTime(Symbol(),判断时间,di),TIME_DATE))==0)
      {
             KaiCang(OP_SELL,首单手数,mTick[0]-新高新低单固定止盈*Point,mTick[0]+新高新低单固定止损*Point,"HL"+TimeToStr(iTime(Symbol(),判断时间,di),TIME_DATE));
             return;
      } 
      
}

void My_GetMaxVolK()
{
 
   int    di=1;
   datetime kTime=0;
      
   if(TimeDayOfWeek(iTime(Symbol(),1440,di))>=1 && TimeDayOfWeek(iTime(Symbol(),1440,di))<=5)
   {
      di=1;
   }else
   {
      di=2;
   }
   
   datetime dTime=iTime(Symbol(),1440,di);
   
   long mVol=0;
   
   for(int i=1;i<Bars;i++)
   {
      if(TimeDay(Time[i])==TimeDay(dTime))
      {
         if(Volume[i]>mVol) {mVol=Volume[i];kTime=Time[i];}
      }
      if(Time[i]<dTime) break;
   }
   
   int ib=iBarShift(Symbol(),0,kTime,false);
   
   if(MathAbs(Open[ib]-Close[ib])>大量K线实体小于*Point) {kTime=Time[ib-1]; ib=ib-1;}
   
   bool stkg=false;
   
   if(Open[ib]<Close[ib] && High[ib]-Close[ib]>大量K线影线小于*Point)  stkg=true;
   if(Open[ib]<Close[ib] && Close[ib]-Low[ib] >大量K线影线小于*Point)  stkg=true;
   if(Open[ib]>Close[ib] && High[ib]-Open[ib] >大量K线影线小于*Point)  stkg=true;
   if(Open[ib]>Close[ib] && Close[ib]-Low[ib] >大量K线影线小于*Point)  stkg=true;
   
   QJ_TIME=Time[ib];
   
   if(stkg && Open[ib]<Close[ib]) {QJ_HIGH=Close[ib]+大量K线区间修正*Point;QJ_LOW=Open[ib]-大量K线区间修正*Point;}
   if(stkg && Open[ib]>Close[ib]) {QJ_HIGH=Open[ib]+大量K线区间修正*Point ;QJ_LOW=Close[ib]-大量K线区间修正*Point;}
   
   if(!stkg) {QJ_HIGH=High[ib]+大量K线区间修正*Point;QJ_LOW=Low[ib]-大量K线区间修正*Point;}
      
}

void My_HighLine(double p)
{
    if(ObjectFind(0,"mHigh")<0)
    {
       bool cl=HLineCreate(0,"mHigh",0,p,clrWhite,STYLE_DOT,1,false,false);
    }else
    {
      ObjectMove(0,"mHigh",0,0,p);
    } 

}

void My_LowLine(double p)
{
    if(ObjectFind(0,"mLow")<0)
    {
       bool cl=HLineCreate(0,"mLow",0,p,clrWhite,STYLE_DOT,1,false,false);
    }else
    {
      ObjectMove(0,"mLow",0,0,p);
    } 

}
  
//持仓单
int my_GetOrderCount(string tm)
{
  int rd=0;
  for(int i=0;i<OrdersTotal();i++)

     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
        {
         if(OrderSymbol()==Symbol()&&OrderComment()==tm && OrderMagicNumber()==识别码)
           {
              rd++;            
           }       
        }
     }
 
   return rd;
}


int my_GetLSOrderCount(string tm)
{
  int rd=0;
  for(int i=OrdersHistoryTotal()-1;i>=0;i--)

     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==True)
        {
         if(OrderSymbol()==Symbol()&&StringFind(OrderComment(),tm)>=0&& OrderMagicNumber()==识别码)
           {
              rd++;            
           }       
        }
     }
 
   return rd;
}

//区间下单数
double my_GetLastYingLi(string tm)
{
  double rd=0;
  for(int i=OrdersHistoryTotal()-1;i>=0;i--)
  {
    if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==True)
    {
      if(OrderSymbol()==Symbol() && StringFind(OrderComment(),tm)>=0 && OrderMagicNumber()==识别码)
      {
         rd=OrderProfit();
         break;            
      }       
    }
  }
 return rd;
}

int my_GetTimeCount2(datetime tm)
{
  int rd=0;
  for(int i=OrdersHistoryTotal()-1;i>=0;i--)
  {
    if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==True)
    {
      if(OrderSymbol()==Symbol() && StringFind(OrderComment(),TimeToStr(tm,TIME_DATE|TIME_MINUTES))>=0 && OrderProfit()>0 && OrderMagicNumber()==识别码)
      {
         rd++;            
      }       
    }
  }
 return rd;
}

int my_GetHLCount(string tm)
{
  int rd=0;
  for(int i=OrdersHistoryTotal()-1;i>=0;i--)
  {
    if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==True)
    {
      if(OrderSymbol()==Symbol() && StringFind(OrderComment(),tm)>=0 && OrderMagicNumber()==识别码)
      {
         rd++;            
      }       
    }
  }
  for(int i=OrdersTotal()-1;i>=0;i--)
  {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==True)
    {
      if(OrderSymbol()==Symbol() && OrderComment()==tm && OrderMagicNumber()==识别码)
      {
         rd++;            
      }       
    }
  }
 return rd;
}

void KaiCang(int ty,double lot,double zy,double zs,string cm)
  {
  //下多单
   if(ty==OP_BUY)
   {
      double a_Ask=MarketInfo(Symbol(),MODE_ASK);
      double a_Bid=MarketInfo(Symbol(),MODE_BID);

      //--- place market order to buy 2 lot
      int ticket1=OrderSend(Symbol(),OP_BUY,lot,a_Ask,3,zs,zy,cm,识别码,0,clrRed);
      if(ticket1<0)
        {
         Print("OrderSend failed with error #",GetLastError());
        }
      else
         Print("OrderSend placed successfully");

   }

   if(ty==OP_SELL)

     {
      double a_Ask=MarketInfo(Symbol(),MODE_ASK);
      double a_Bid=MarketInfo(Symbol(),MODE_BID);

      //--- place market order to buy 2 lot
      int ticket1=OrderSend(Symbol(),OP_SELL,lot,a_Bid,3,zs,zy,cm,识别码,0,clrGreen);
      if(ticket1<0)
        {
         Print("OrderSend failed with error #",GetLastError());
        }
      else
         Print("OrderSend placed successfully");

     }

  }
  
  
  bool HLineCreate(const long            chart_ID=0,        // chart's ID 
                 const string          name="HLine",      // line name 
                 const int             sub_window=0,      // subwindow index 
                 double                price=0,           // line price 
                 const color           clr=clrRed,        // line color 
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style 
                 const int             width=1,           // line width 
                 const bool            back=false,        // in the background 
                 const bool            selection=true,    // highlight to move 
                 const bool            hidden=true,       // hidden in the object list 
                 const long            z_order=0)         // priority for mouse click 
  { 
//--- if the price is not set, set it at the current Bid price level 
   if(!price) 
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID); 
//--- reset the error value 
   ResetLastError(); 
//--- create a horizontal line 
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price)) 
     { 
      Print(__FUNCTION__, 
            ": failed to create a horizontal line! Error code = ",GetLastError()); 
      return(false); 
     } 
//--- set line color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- set line display style 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
//--- set line width 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- enable (true) or disable (false) the mode of moving the line by mouse 
//--- when creating a graphical object using ObjectCreate function, the object cannot be 
//--- highlighted and moved by default. Inside this method, selection parameter 
//--- is true by default making it possible to highlight and move the object 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
//--- successful execution 
   return(true); 
  } 
  void My_SetRectangle(datetime rt)
  {
  
    
      if(ObjectFind(0,Symbol()+"_"+TimeToStr(QJ_TIME,TIME_DATE))<0)
      {       
         RectangleCreate(0,Symbol()+"_"+TimeToStr(QJ_TIME,TIME_DATE),0,QJ_TIME,QJ_HIGH,Time[0],QJ_LOW,clrBlue,0,1,true,true,false);
      }else
      {
        if(ObjectGetInteger(0,Symbol()+"_"+TimeToStr(QJ_TIME,TIME_DATE),OBJPROP_TIME2)!=Time[0])
        {
          ObjectSetInteger(0,Symbol()+"_"+TimeToStr(QJ_TIME,TIME_DATE),OBJPROP_TIME2,Time[0]);
        }    
      }
      

  }
  
  
  
//平仓操作
void PingCang()

  {

  
      bool a=true;
      do

        {

         for(int i=0;i<OrdersTotal();i++)
           {

            if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)

              {
               int sOrderX=OrderTicket();
               double a_Bid=MarketInfo(OrderSymbol(),MODE_BID);
               double a_Ask= MarketInfo(OrderSymbol(),MODE_ASK);



               if(OrderSymbol()==Symbol())
                 {
                  if(OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),30,Blue)==true)

                    {
                     Print(OrderSymbol()+"平仓成功！");
                    }
                  else
                    {
                     Print(OrderSymbol()+"平仓失败！错误号="+IntegerToString(GetLastError()));
                    }
                 }

              }
           }

         a=False;
         //检测定单是否平仓完毕，如果没有平完，刚修改参数
         for(int j=0;j<OrdersTotal();j++)
           {
            if(OrderSelect(j,SELECT_BY_POS,MODE_TRADES)==true)

              {

               if(OrderSymbol()==Symbol())

                 {
                  a=True;
                  break;
                 }

              }


           }

        }
      while(a==True);
   
  }
  
  
  bool RectangleCreate(const long            chart_ID=0,        // chart's ID 
                     const string          name="Rectangle",  // rectangle name 
                     const int             sub_window=0,      // subwindow index  
                     datetime              time1=0,           // first point time 
                     double                price1=0,          // first point price 
                     datetime              time2=0,           // second point time 
                     double                price2=0,          // second point price 
                     const color           clr=clrRed,        // rectangle color 
                     const ENUM_LINE_STYLE style=STYLE_SOLID, // style of rectangle lines 
                     const int             width=1,           // width of rectangle lines 
                     const bool            fill=false,        // filling rectangle with color 
                     const bool            back=false,        // in the background 
                     const bool            selection=true,    // highlight to move 
                     const bool            hidden=true,       // hidden in the object list 
                     const long            z_order=0)         // priority for mouse click 
  { 
//--- set anchor points' coordinates if they are not set 
   ChangeRectangleEmptyPoints(time1,price1,time2,price2); 
//--- reset the error value 
   ResetLastError(); 
//--- create a rectangle by the given coordinates 
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE,sub_window,time1,price1,time2,price2)) 
     { 
      Print(__FUNCTION__, 
            ": failed to create a rectangle! Error code = ",GetLastError()); 
      return(false); 
     } 
//--- set rectangle color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- set the style of rectangle lines 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
//--- set width of the rectangle lines 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
//--- enable (true) or disable (false) the mode of filling the rectangle 
   ObjectSetInteger(chart_ID,name,OBJPROP_FILL,fill); 
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- enable (true) or disable (false) the mode of highlighting the rectangle for moving 
//--- when creating a graphical object using ObjectCreate function, the object cannot be 
//--- highlighted and moved by default. Inside this method, selection parameter 
//--- is true by default making it possible to highlight and move the object 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
//--- successful execution 
   return(true); 
  } 
//+------------------------------------------------------------------+ 
//| Move the rectangle anchor point                                  | 
//+------------------------------------------------------------------+ 
bool RectanglePointChange(const long   chart_ID=0,       // chart's ID 
                          const string name="Rectangle", // rectangle name 
                          const int    point_index=0,    // anchor point index 
                          datetime     time=0,           // anchor point time coordinate 
                          double       price=0)          // anchor point price coordinate 
  { 
//--- if point position is not set, move it to the current bar having Bid price 
   if(!time) 
      time=TimeCurrent(); 
   if(!price) 
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID); 
//--- reset the error value 
   ResetLastError(); 
//--- move the anchor point 
   if(!ObjectMove(chart_ID,name,point_index,time,price)) 
     { 
      Print(__FUNCTION__, 
            ": failed to move the anchor point! Error code = ",GetLastError()); 
      return(false); 
     } 
//--- successful execution 
   return(true); 
  } 

void ChangeRectangleEmptyPoints(datetime &time1,double &price1, 
                                datetime &time2,double &price2) 
  { 
//--- if the first point's time is not set, it will be on the current bar 
   if(!time1) 
      time1=TimeCurrent(); 
//--- if the first point's price is not set, it will have Bid value 
   if(!price1) 
      price1=SymbolInfoDouble(Symbol(),SYMBOL_BID); 
//--- if the second point's time is not set, it is located 9 bars left from the second one 
   if(!time2) 
     { 
      //--- array for receiving the open time of the last 10 bars 
      datetime temp[10]; 
      CopyTime(Symbol(),Period(),time1,10,temp); 
      //--- set the second point 9 bars left from the first one 
      time2=temp[0]; 
     } 
//--- if the second point's price is not set, move it 300 points lower than the first one 
   if(!price2) 
      price2=price1-300*SymbolInfoDouble(Symbol(),SYMBOL_POINT); 
  } 
  
void MdOrder()
{
   if(盈保点数<=0) return;
   for (int i=0;i<OrdersTotal();i++)
     {
        bool od=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
        if(OrderMagicNumber()==识别码&&OrderSymbol()==Symbol())
        {  
             if(OrderType()==OP_BUY && OrderStopLoss()<OrderOpenPrice() && OrderTakeProfit()-Bid<=距离止盈线距离激活盈保*Point ) {bool om= OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+盈保点数*Point,OrderTakeProfit(),0,clrYellow);};
             if(OrderType()==OP_SELL&& OrderStopLoss()>OrderOpenPrice() && Ask-OrderTakeProfit()<=距离止盈线距离激活盈保*Point)  {bool om= OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-盈保点数*Point,OrderTakeProfit(),0,clrYellow);};
         }
     }
}




