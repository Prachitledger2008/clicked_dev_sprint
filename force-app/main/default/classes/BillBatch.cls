public with sharing class BillBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    public List<Id> receivesBillByEmail = new List<Id>();
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        //this is a method that will query for all accounts that are active and have a value
        //for Bill_By_Email__c (Account.Active__c = \'Yes\' AND Bill_By_Email != null)
        //using the Database.getQueryLocator(String) method. Return the result of this method.
        //Hint: be sure to escape the single quotes surrounding \'Yes\' in your dynamic query!
        //query for the following fields:
        //Id, Bill_By_Email__c
        String query = 'SELECT Id, Bill_By_Email__c FROM Account WHERE Active__c = \'Yes\' AND Bill_By_Email__c != null';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope){
        //this is a method that will process the queried for records by preparing
        //a list of account Ids (this.receivesBillByEmail) to carry over to the finish method.
        //we will do this by iterating over scope and checking whether Bill_By_Email__c == TRUE.
        //This method will also call our BillAPI.getBills() method.
        for (Account acc : scope) {
            if (acc.Bill_By_Email__c) {
                receivesBillByEmailIds.add(acc.Id);
            }
        }

        // Call an external method (BillAPI.getBills()) to process the list of account Ids
        // You may need to implement the BillAPI class and the 'getBills' method
        BillAPI.getBills(receivesBillByEmailIds); // Pass the list to the external method

    }

    public void finish(Database.BatchableContext bc) {
        // Step 1: Query for the most recent bills for each account
        Map<Id, Id> billMap = new Map<Id, Id>();
        Map<Id, String> emailMap = new Map<Id, String>();
    
        List<Account> accountsWithRecentBills = [SELECT Id, (SELECT Id FROM Bills__r ORDER BY CreatedDate DESC LIMIT 1) FROM Account WHERE Id IN :this.receivesBillByEmail];
    
        for (Account acc : accountsWithRecentBills) {
            if (acc.Bills__r.size() > 0) {
                billMap.put(acc.Id, acc.Bills__r[0].Id);
                emailMap.put(acc.Id, acc.Email__c);
            }
        }
    
        // Step 2: Prepare and send emails
        BillEmailer billEmailer = new BillEmailer();
    
        for (Id accountId : billMap.keySet()) {
            String email = emailMap.get(accountId);
            Id billId = billMap.get(accountId);
    
            // Step 3: Generate PDF for the bill
            PageReference pageRef = Page.BillVFP;
            pageRef.getParameters().put('id', billId);
            Blob pdfBlob = pageRef.getContentAsPDF();
    
            // Step 4: Prepare the map for sending emails
            Map<String, Blob> sendMap = new Map<String, Blob>();
            sendMap.put(email, pdfBlob);
    
            // Step 5: Send the email
            billEmailer.sendEmails(sendMap);
        }
    }
    
}