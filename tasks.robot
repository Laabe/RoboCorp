*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${False}
Library    RPA.Tables
Library    RPA.HTTP
Library    RPA.PDF
Library    RPA.Desktop
Library    RPA.Archive
Library    RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser
    Log    Done

*** Keywords ***
Open the robot order website
    ${secrets}=    Get Secret    Robot_Information
    Open Available Browser    ${secrets}[Robot_website]

Get orders
    ${secrets}=    Get Secret    Robot_Information
    Download    ${secrets}[orders_url]    overwrite=${True}
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}  

Close the annoying modal
    Wait Until Element Is Visible    css:div.alert-buttons
    Click Button    OK    

Fill the form
    [Arguments]    ${row}
    Wait Until Element Is Visible    xpath:/html/body/div/div/div[1]/div/div[1]/form
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Press Key    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Wait Until Element Is Enabled    id:preview
    Wait Until Keyword Succeeds    3x    2s    Click Button    id:preview

Submit the order
    Wait Until Element Is Visible    id:order
    Click Button    id:order
        
Go to order another robot
    Wait Until Keyword Succeeds    10x    1s    Wait Until Element Is Visible    id:order-another
    Click Button    Order another robot
    ${state}=    Does Page Contain Element    id:order-another
    Log    ${state}
    WHILE    ${state} == ${True}
        Click Button    Order another robot
        ${state}=    Does Page Contain Element    id:order-another
    END
    # Wait Until Keyword Succeeds    3x    3s    Click Button    Order another robot

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt_state}=    Does Page Contain Element    id:receipt
    WHILE    ${receipt_state} == ${False}
        Wait Until Keyword Succeeds    3x    1s    Submit the order
        ${receipt_state}=    Does Page Contain Element    id:receipt
    END    
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}receipts${/}receipt_${order_number}.pdf
    RETURN    ${OUTPUT_DIR}${/}receipts${/}receipt_${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}screenshots${/}robot-${order_number}.png
    RETURN    ${OUTPUT_DIR}${/}screenshots${/}robot-${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List    ${screenshot}   
    Open Pdf    ${pdf}
        Add Files To Pdf      ${files}    ${pdf}    append=True   
    Close Pdf
    

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}receipts.zip