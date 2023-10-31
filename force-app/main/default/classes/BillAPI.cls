public with sharing class BillAPI {
    
    public static void getBills() {
         HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Billing_API');
        req.setMethod('GET');
        req.setHeader('Content-Type','application/json; charset=UTF-8');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        list<BillWrapper> billWrap ;
       if(res.getStatusCode() == 200) {
		billWrap= (list<BillWrapper>)JSON.deserialize(res.getBody(),list<BillWrapper>.class);
        }
        
		List<Account>activeAcc=[select id,name from Account where Active__c = 'Yes' ];
        Map<String, Id> accMap=new map<String,Id>();
        for(Account acc:activeAcc){
            accMap.put(acc.Name,acc.Id);
        }
       	List<Bill__c>billList=new List<Bill__c>();
        for(BillWrapper blist :billWrap){
            if(accMap.containsKey(blist.accountName)){
             Bill__c bill=new Bill__c();
             bill.Account__c=accMap.get(blist.accountName);
             bill.Bill_Id__c=blist.billId;
             bill.Balance__c=Decimal.valueOf(blist.balance.replace('$', ''));
             billList.add(bill);
            }
        }
        
        Schema.SobjectField externalIdField=Bill__c.Fields.Bill_Id__c;
        boolean allOrNone=false;
        Database.UpsertResult[] srList=Database.Upsert(billList,externalIdField,allOrNone);
        for (Database.UpsertResult sr : srList) {
    if (sr.isSuccess()) {
         //Operation was successful
    }
    else {
        // Operation failed, so get all errors                
        for(Database.Error err : sr.getErrors()) {
            System.debug('error has occurred.' + err.getStatusCode() + ': ' + err.getMessage());                    
            System.debug('fields that affected this error: ' + err.getFields());
            
        }//
    }
}
		List<Bill__c>bc=[select id from Bill__c];
        System.debug(bc);
        
    }

    public class BillWrapper {
        public String billId;
        public String accountName;
        public String balance;
    }
}