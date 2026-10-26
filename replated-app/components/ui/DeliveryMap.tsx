import React from 'react';
import MapView, { Marker } from 'react-native-maps';

type Props={riderLat:number;riderLon:number;ngoPoint?:{latitude:number;longitude:number}|null;style?:any;};
export default function DeliveryMap({riderLat,riderLon,ngoPoint,style}:Props){
  const region=ngoPoint?{latitude:(riderLat+ngoPoint.latitude)/2,longitude:(riderLon+ngoPoint.longitude)/2,latitudeDelta:Math.max(0.025,Math.abs(riderLat-ngoPoint.latitude)*1.5),longitudeDelta:Math.max(0.025,Math.abs(riderLon-ngoPoint.longitude)*1.5)}:{latitude:riderLat,longitude:riderLon,latitudeDelta:0.025,longitudeDelta:0.025};
  return <MapView style={style} initialRegion={region} region={region}><Marker coordinate={{latitude:riderLat,longitude:riderLon}} title="Delivery partner" description="Current rider location"/>{ngoPoint&&<Marker coordinate={ngoPoint} title="Your NGO" pinColor="green"/>}</MapView>;
}
