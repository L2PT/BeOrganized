const webPushNotificationsVapidKey = 'BJstIUpFNSxgd1Ir1xQd_qt48ijnfLG2B3Md_9unMkA7nMBpZZRVX3_6A5f2HJJLCOZJoFH2CgpmtrimGRe-rWo';

var debug = false;
var calendar;
var db;
var storage;
var categories;
var dart;
var idUtente;

$(function() {
  messaging = firebase.messaging();
  db = firebase.firestore();
  storage = firebase.storage();
      
  //Initialize Categories
  var docRef = db.collection(debug?"Costanti_DEBUG":"Costanti").doc("Categorie");
  docRef.get().then(function(doc) {
      if (doc.exists) {
          categories = doc.data();
          categories['default'] = '#fda90a';
      } else {
          console.log("No categories!");
      }
  }).catch(function(error) {
      console.log("Error getting categories:", error);
  });
});

function init(debug, idUtente){
  this.debug = debug;
  this.idUtente = idUtente;
  setupMessagingHandler();
  
  $('#__file_picker_web-file-input').hide()
}

/*-------------------------------------------------------------------*/
                        /*--UTILITIES--*/

function setupMessagingHandler() {
  console.log('Checking notification permissions...');
  Notification.requestPermission().then((permission) => {
    if (permission === 'granted') {      
      try{
        messaging = firebase.messaging();
        messaging.onMessage((payload) => {
            message = payload.data.title.split("\"")[0];
            job = payload.data.title.split("\"")[1];
            type = payload.data.style;
            window.createNotification({
               closeOnClick: true,
               displayCloseButton: true,
               // nfc-top-left
               // nfc-bottom-right
               // nfc-bottom-left
               positionClass: 'nfc-top-right',
               // callback
               onclick: () => {
                openEventDetails_dart(payload.data.id);
               },
               showDuration: 60000,
               // success, info, warning, error, and none
               theme: type
             })({
               title: job,
               message: message
            });
            console.log('Message received on focus: ', payload);
        });
        messaging.getToken({ vapidKey: webPushNotificationsVapidKey }).then((currentToken) => {
          if (currentToken) {
            console.log("Got a token: ", currentToken)
            updateAccontTokens_dart(currentToken);
          } else {
            console.log('No registration token available. Request permission to generate one.');
          }
        }).catch((err) => {
          console.log('An error occurred while retrieving token. ', err);
        });
      }catch(e){
        console.log(e)
      }
    }
  });
}
/*          DART            */
//accessors
function showAlertJs(value) { alert(value);}
function consoleLogJs(value) { console.log(value);}






