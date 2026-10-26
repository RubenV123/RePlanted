import React from 'react';
import DateTimePicker, { type DateTimePickerEvent } from '@react-native-community/datetimepicker';

type Props={value:string;onChange:(value:string)=>void;onDismiss:()=>void;background?:string;border?:string;color?:string;};
function asDate(value:string){const [hours,minutes]=value.split(':').map(Number);const date=new Date();date.setHours(hours||0,minutes||0,0,0);return date;}
export function TimePickerControl({value,onChange,onDismiss}:Props){
  return <DateTimePicker mode="time" display="default" value={asDate(value)} onChange={(event:DateTimePickerEvent,date?:Date)=>{if(event.type==='set'&&date)onChange(`${String(date.getHours()).padStart(2,'0')}:${String(date.getMinutes()).padStart(2,'0')}`);onDismiss();}}/>;
}
