/**
 **	Created by François Gardien (FGSolutions)
 * 	Date : 2014 
 *	License : GNU v2
 **/
package com.FGSolutions.exportVCard
{
	import com.jam3media.shareExt.ShareExt;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.setTimeout;
	
	import mx.charts.CategoryAxis;
	import mx.collections.ArrayCollection;
	
	public class ExportVCard
	{
		public var nativePathFile:String = "";
		public var strFileName:String = "";
		public var flagFileVCFCreated:Boolean;
		public var strIOError:String = "";
		public var fileDestination:File;
		public var flagShareFichierVCF:Boolean;
		
		public function ExportVCard() {}
		
		public function init(acContacts:ArrayCollection, version:uint=2):Boolean
		{	
			var bFileVCF_isEmpty:Boolean= true;
			if(acContacts.length>0){
				
				var contentVCard:String;
				if(version==4)
					contentVCard = parse_VCardv4_0(acContacts);
				else
					contentVCard = parse_VCardv2_1(acContacts);
				
				var file:File = new File();
				var dateNow:Date = new Date();
				var strTimevalue:String = String(dateNow.time);
				
				strFileName = "myExportedContacts"+strTimevalue+".VCF";
				
				fileDestination = File.documentsDirectory;
				fileDestination = fileDestination.resolvePath(strFileName);
				nativePathFile = fileDestination.nativePath;
				trace("fileDestination.nativePath =" + fileDestination.nativePath + " ; fileDestination.name ="+fileDestination.name);
				var fileStream:FileStream = new FileStream();
				fileStream.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				fileStream.openAsync(fileDestination, FileMode.WRITE);
				fileStream.writeUTFBytes(contentVCard);
				fileStream.addEventListener(Event.CLOSE, onCloseFileStream);
				var timer:uint = setTimeout(function(){
					fileStream.close();
				},50);
			}
			else{
				bFileVCF_isEmpty = false;
			}
			return bFileVCF_isEmpty;
		}
		
		/**
		 * The VCard v4.0 specification is not accepted by the Contact App on tested Android Kitkat, neither Android v2.3.3
		 * 
		 **/
		protected function parse_VCardv4_0(acContacts:ArrayCollection):String
		{
			var contentVCard:String = "";
			var i:int = 0;
			for each(var elt:Object in acContacts){
				
				var strName:String = elt.name.replace(",","\,");
				var strFirstname:String = elt.firstname.replace(",","\,");
				var strFN:String
				if(elt.hasOwnProperty("firstname")){ // Detect if element is a people, or an organization.
					if(strFirstname!="")
						strFN = strFirstname+" "+strName;
					else 
						strFN = strName;
				}
				var strAddress1:String = elt.address.replace(",","\,");
				var strCity:String = elt.city.replace(",","\,");
				var strRegion:String = elt.address.replace(",","\,");
				
				contentVCard = contentVCard + "BEGIN:VCARD\n"+
					"VERSION:4.0\n";
				if(elt.hasOwnProperty("firstname")){
					contentVCard = contentVCard + "N:"+strName+";"+strFirstname+";;;\n";
					contentVCard = contentVCard + "FN:"+strFirstname+" "+elt.name+"\n";
				}
				else{
					contentVCard = contentVCard + "N:"+strName+";;;;\n";
					contentVCard = contentVCard + "FN:"+strName+"\n";
				}
				// This attribute defines the professional type for the VCard : so it is a people or an organization
				if(elt.professional){
					contentVCard = contentVCard + "KIND:org\n";
					if(strName!="")
						contentVCard = contentVCard + "ORG:"+strName+"\n";
					if(elt.workPhone!="")
						contentVCard = contentVCard + "TEL;TYPE=\"work\":tel:"+elt.workPhone+"\n";
				}
				else
				{
					if(elt.homePhone!="")
						contentVCard = contentVCard + "TEL;TYPE=\"home\":tel:"+elt.homePhone+"\n";
					if(elt.gsm!="")
						contentVCard = contentVCard + "TEL;TYPE=\"cell\":tel:"+elt.gsm+"\n";
				}
				contentVCard = contentVCard + "EMAIL:"+elt.email+"\n";
				if(strAddress1!="" || elt.postalCode!="" || strCity!=""){
					// This attribute defines the professional type for the VCard : so it is a people or an organization
					if(elt.professional){
						contentVCard = contentVCard + "ADR;TYPE=work:"+strLabelAddress+";"+strAddress1 +";"+ strCity +";"+strRegion+";"+ elt.postalCode +";\n";
					}
					else{ 							
						var strLabelAddress:String;
						if(strRegion!="")
							strLabelAddress = "\""+ strAddress1 +"\n"+strCity+" ,"+strRegion+" "+elt.postalCode +"\"";
						else
							strLabelAddress = "\""+ strAddress1 +"\n"+elt.postalCode+" "+strCity+"\"";
						
						contentVCard = contentVCard +  "ADR;TYPE=home:"+strLabelAddress+";"+strAddress1 +";"+ strCity +";,"+strRegion+";"+ elt.postalCode +";\n";
					}
				}
				contentVCard = contentVCard + "END:VCARD";
				if(i<acContacts.length)
					contentVCard += "\n";
				i++;
				trace("contentVCard = "+contentVCard);
			}
			debugAcContactsLength = i;
			return contentVCard;
		}

		/**
		 * The VCard v2.1 specification is really accepted by the Contact App on tested Android Kitkat, and therefore by Android v2.3.3
		 **/
		protected function parse_VCardv2_1(acContacts:ArrayCollection):String
		{
			var contentVCard:String = "";
			var i:int = 1;
			for each(var elt:Object in acContacts){
				contentVCard = contentVCard + "BEGIN:VCARD\n"+
					"VERSION:2.1\n";
				if(elt.hasOwnProperty("firstname")){
					contentVCard = contentVCard + "N:"+elt.name+";"+elt.firstname+";;;\n";
					contentVCard = contentVCard + "FN:"+elt.firstname+" "+elt.name+"\n";
				}
				else{
					contentVCard = contentVCard + "N:"+elt.name+";;;;;\n";
					contentVCard = contentVCard + "FN:"+elt.name+"\n";
				}
				// This attribute defines the professional type for the VCard : so it is a people or an organization
				if(elt.professional){
					if(elt.name!="")
						contentVCard = contentVCard + "ORG:"+elt.name+"\n";
					if(elt.workPhone!="")
						contentVCard = contentVCard + "TEL;WORK:"+elt.workPhone+"\n";
				}
				else
				{
					if(elt.homePhone!="")
						contentVCard = contentVCard + "TEL;HOME:"+elt.homePhone+"\n";
					if(elt.gsm!="")
						contentVCard = contentVCard + "TEL;CELL:"+elt.gsm+"\n";
				}
				contentVCard = contentVCard + "EMAIL;PREF:"+elt.email+"\n";
				if(elt.address!="" || elt.postalCode!="" || elt.city!=""){
					// This attribute defines the professional type for the VCard : so it is a people or an organization
					if(elt.professional){
						contentVCard = contentVCard + "ADR;WORK:;;"+elt.address +";"+ elt.city +";"+elt.region+";"+ elt.postalCode +";\n";
					}
					else{ 							
						contentVCard = contentVCard + "ADR;HOME:;;"+elt.address +";"+ elt.city +";"+elt.region+";"+ elt.postalCode +";\n";
					}
				}
				contentVCard = contentVCard + "END:VCARD";
				if(i<acContacts.length)
					contentVCard += "\n";
				i++;
				trace("contentVCard = "+contentVCard);
			}
			debugAcContactsLength = i;
			return contentVCard;
		}
		
		// Debug :
		public var debugAcContactsLength:uint;
		/**
		 ** Return : 0 is for empty, 1 is for no empty
		 **/
				
		
		private function onCloseFileStream(e:Event):void
		{	
			flagFileVCFCreated = true;
		}
		
		private function onIOError(e:IOErrorEvent):void
		{	
			strIOError = e.errorID +" : "+ e.text;
		}
	}
}