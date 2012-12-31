import 'dart:html';
import 'dart:json';
import 'package:js/js.dart' as js;

final String CLIENT_ID = '299615367852.apps.googleusercontent.com';
final String SCOPE = 'https://www.googleapis.com/auth/drive';

void main() {
  js.scoped((){
    void insertFile(File fileData, [callback = null]) {
      String boundary = '-------314159265358979323846';
      String delimiter = "\r\n--$boundary\r\n";
      String close_delim = "\r\n--$boundary--";

      var reader = new FileReader();
      reader.readAsBinaryString(fileData);
      reader.on.load.add((Event e) {
        var contentType = fileData.type;
        if (contentType.isEmpty) {
          contentType = 'application/octet-stream';
        }

        var metadata = {
          'title' : fileData.name,
          'mimeType' : contentType
        };

        var base64Data = window.btoa(reader.result);
        var sb = new StringBuffer();
        sb
        ..add(delimiter)
        ..add('Content-Type: application/json\r\n\r\n')
        ..add(JSON.stringify(metadata))
        ..add(delimiter)
        ..add('Content-Type: ')
        ..add(contentType)
        ..add('\r\n')
        ..add('Content-Transfer-Encoding: base64\r\n')
        ..add('\r\n')
        ..add(base64Data)
        ..add(close_delim);

        var multipartRequestBody = sb.toString();

        print("multipartRequestBody");
        print(multipartRequestBody);

        js.scoped(() {
          var request = js.context.gapi.client.request(
            js.map({
              'path': '/upload/drive/v2/files',
              'method': 'POST',
              'params': {'uploadType': 'multipart'},
              'headers': {
                'Content-Type': 'multipart/mixed; boundary="$boundary"'
              },
              'body': multipartRequestBody
            }));

          if (callback == null) {
            callback = new js.Callback.many((js.Proxy jsonResp, var rawResp) {
              print(js.context.JSON.stringify(jsonResp));
              print(rawResp);

              Map r = JSON.parse(js.context.JSON.stringify(jsonResp));
              StringBuffer sb = new StringBuffer();
              if (r.containsKey('error')) {
                sb.add(r.toString());
              } else {
                sb.add("${r["title"]} has been uploaded.");
              }

              query('#text').text = sb.toString();
            });
          }

          request.execute(callback);
        });

      });
    };

    void uploadFile(Event evt) {
      js.scoped( () {
        js.context.gapi.client.load('drive', 'v2', new js.Callback.many(() {
          var file = evt.target.files[0];
          insertFile(file);
        }));
      });
    }

    js.context.handleAuthResult = new js.Callback.many((js.Proxy authResult) {
      Map dartAuthResult = JSON.parse(js.context.JSON.stringify(authResult));
      print("dartAuthResult = ${dartAuthResult}");

      var authButton = query('#authorizeButton');
      var filePicker = query('#filePicker');
      authButton.style.display = 'none';
      filePicker.style.display = 'none';

      if (!dartAuthResult.containsKey('error')) {
        // Access token has been successfully retrieved, requests can be sent to the API.
        filePicker.style.display = 'block';
        filePicker.on['change'].add(uploadFile);
      } else {
        authButton.style.display = 'block';
        authButton.on.click.add((Event e) {
          js.scoped(() {
            js.context.gapi.auth.authorize(
                js.map({
                    'client_id': CLIENT_ID,
                    'scope': SCOPE,
                    'immediate': true
                  }),
                  js.context.handleAuthResult);
          });
        });
      }
    });

    js.context.handleClientLoad =  new js.Callback.many(() {
      js.context.window.setTimeout(js.context.checkAuth, 1);
    });

    js.context.checkAuth = new js.Callback.many(() {
      js.context.gapi.auth.authorize(
          js.map({
              'client_id': CLIENT_ID,
              'scope': SCOPE,
              'immediate': true
            }),
            js.context.handleAuthResult);
    });
  });

  ScriptElement script = new ScriptElement();
  script.src = "http://apis.google.com/js/client.js?onload=handleClientLoad";
  script.type = "text/javascript";
  document.body.children.add(script);
}