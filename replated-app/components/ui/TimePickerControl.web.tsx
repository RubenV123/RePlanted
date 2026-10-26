import React from 'react';

type Props={value:string;onChange:(value:string)=>void;onDismiss:()=>void;background?:string;border?:string;color?:string;};
export function TimePickerControl({value,onChange,background='#FFFFFF',border='#DCE4DC',color='#17211B'}:Props){
  return React.createElement('input' as any,{type:'time',value,onChange:(event:any)=>onChange(event.target.value),'aria-label':'Select time',style:{...inputStyle,backgroundColor:background,border:`1px solid ${border}`,color}});
}
const inputStyle={height:50,marginTop:10,padding:'0 14px',borderRadius:14,border:'1px solid #DCE4DC',background:'#FFFFFF',color:'#17211B',fontSize:15} as any;
