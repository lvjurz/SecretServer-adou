# SecretServer-adou
Powershell script designed to be used in Delinea SecretServer to update connection hosts based on AD OU content

# Requirements
* A template
* API account
* A secret
* PowerShell script
* User or AD group that will contain users that can use this secret
* AD OU (organizational unit) that will contain servers

# Template
1. Settings -> Secret templates -> Active Directory account -> Duplicate
   Name: New-AD-restricted
   
2. Fields -> Add field
    Name: OUname
    Slug: ouname
    Description: OU of servers
    Type: Text

3. Settings -> Secret templates -> pick-template -> Mapping -> Launcher restrictions -> Edit
   Restrict user input: check
   Use list fields: uncheck
   Restrict as: Allowed list
   Restrict by secret field: Notes
   Include machine from dependencies: uncheck

# API account
1. Access->Users->Create user
   Application account: check
   
# Secret
1. Create a folder for particular application
   Secrets -> Folders -> +

2. Grant 'Edit' access for API account to Folder that contains secret/secrets
   
3. Grant 'View' access to user/ADgroup that will use the secret

4. Create a secret using new template in newly created folder
   Fill in OUname (ie. OU=Application,OU=Servers,OU=DC,OU=Units,DC=mycompany,DC=lan)
   Save

Launch secret with user!
