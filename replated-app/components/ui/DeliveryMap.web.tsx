import React from 'react';

type Props={riderLat:number;riderLon:number;ngoPoint?:{latitude:number;longitude:number}|null;style?:any;};
export default function DeliveryMap({riderLat,riderLon}:Props){
  const src=`https://maps.google.com/maps?q=${riderLat},${riderLon}&z=14&output=embed`;
  return React.createElement('iframe' as any,{title:'Live rider location map',loading:'lazy',src,style:frameStyle,referrerPolicy:'no-referrer-when-downgrade'});
}
const frameStyle={width:'100%',height:230,border:0,borderRadius:15,marginTop:10} as any;
