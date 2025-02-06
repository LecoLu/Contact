import { abilityAccessCtrl, common, PermissionRequestResult, Permissions, Want } from '@kit.AbilityKit';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { promptAction } from '@kit.ArkUI';
import { contact } from '@kit.ContactsKit';


export class SmsContact {
  contactsName: string;
  telephone: string;

  constructor(contactsName: string, telephone: string) {
    this.contactsName = contactsName;
    this.telephone = telephone;
  }
}


let storage = LocalStorage.getShared();

@Entry(storage)
@Component
struct Index {
  @State content: string = '';
  private want: Want | undefined = storage?.get<Want>('ShareUIAbilityWant');
  private sendSmsContact: SmsContact[] = []
  private successContact: contact.Contact[] = []
  private failContact: contact.Contact[] = []

  onPageShow(): void {
    console.error("@@@==========="+JSON.stringify(this.want))

    systemShare.getSharedData(this.want).then((data: systemShare.SharedData) => {
      let records: systemShare.SharedRecord[] = data.getRecords();
      records.forEach(async (record: systemShare.SharedRecord) => {
        switch (record.utd) {
          case uniformTypeDescriptor.UniformDataType.TEXT:
            record.content && (this.content = record.content);
            break;
          case uniformTypeDescriptor.UniformDataType.PLAIN_TEXT:
            record.content && (this.content = record.content);
            break;
          default:
            break;
        }
      });
    })
  }

  save() {
    let context = getContext(this) as common.UIAbilityContext;
    const permissions: Array<Permissions> = ['ohos.permission.WRITE_CONTACTS', 'ohos.permission.READ_CONTACTS'];

    abilityAccessCtrl.createAtManager()
      .requestPermissionsFromUser(context, permissions)
      .then(async (result: PermissionRequestResult) => {
        if (this.content) {
          const strArray: string[] = this.content.split("\n")
          console.error("联系人数据=======================" + strArray)
          this.sendSmsContact = []
          this.successContact = []
          this.failContact = []
          for (let i = 0; i < strArray.length; i++) {
            if (canIUse("SystemCapability.Applications.ContactsData")) {
              const contactContent = strArray[i].trim()
              if (contactContent) {
                const name = contactContent.slice(0, contactContent.length - 11)
                const mobile = contactContent.slice(contactContent.length - 11, contactContent.length)
                const contactInfo: contact.Contact = {
                  name: {
                    fullName: name
                  },
                  phoneNumbers: [
                    {
                      phoneNumber: mobile
                    }
                  ]
                }
                try {
                  const id = await contact.addContact(context, contactInfo)
                  if (id > 0) {
                    this.successContact.push(contactInfo)
                    this.sendSmsContact.push(new SmsContact(name, mobile))
                  } else {
                    this.failContact.push(contactInfo)
                  }
                } catch (e) {
                  this.failContact.push(contactInfo)
                }
              }
            } else {
              console.error("不支持的api====")
            }
          }
          this.content=""
          if (this.successContact || this.failContact) {
            this.showResultDialog()
          }
        } else {
          promptAction.showToast({
            message: "联系人数据为空",
            alignment: Alignment.Center
          })
        }
      })
      .catch((err: BusinessError) => {
        promptAction.showToast({
          message: "没有添加联系人权限",
          alignment: Alignment.Center
        })
      })
  }

  showResultDialog() {
    AlertDialog.show({
      title: "导出结果",
      message: `保存成功：${this.successContact.length} 个;保存失败：${this.failContact.length} 个`,
      alignment: DialogAlignment.Center,
      confirm: {
        value: "确定",
        action: () => {

        }
      }
    })
  }

  startMsgPage() {
    let want: Want = {
      bundleName: "com.ohos.mms",
      abilityName: "com.ohos.mms.MainAbility",
      parameters: {
        contactObjects: JSON.stringify(this.sendSmsContact),
        pageFlag: "conversation",
        // 这里填写短信内容
        content: ""
      }
    }

    const context = getContext(this) as common.UIAbilityContext;
    context.startAbilityForResult(want).then((data) => {
      console.log("发送短信成功====Success" + JSON.stringify(data))
    }).catch((err: BusinessError) => {
      console.log("发送短信失败====error" + JSON.stringify(err))
    })
  }

  build() {
    RelativeContainer() {
      TextArea({ text: this.content, placeholder: "请输入内容" })
        .height("50%")
        .fontSize(18)
        .fontColor("#333333")
        .margin(20)
        .alignRules({
          top: { anchor: '__container__', align: VerticalAlign.Top },
          start: { anchor: '__container__', align: HorizontalAlign.Start },
          end: { anchor: '__container__', align: HorizontalAlign.End }
        })
        .onChange((value) => {
          this.content = value
        })

      Row() {
        Stack() {
          PasteButton()
            .layoutDirection(SecurityComponentLayoutDirection.VERTICAL)
            .backgroundColor(Color.White)
            .iconSize(36)
            .iconColor("#101317")
            .textIconSpace(5)
            .fontSize(16)
            .fontColor("#333333")
            .onClick((event: ClickEvent, result: PasteButtonOnClickResult) => {
              if (PasteButtonOnClickResult.SUCCESS === result) {
                pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                  if (err) {
                    return;
                  }
                  this.content = pasteData.getPrimaryText();
                });
              }
            })
        }.layoutWeight(1)

        Stack() {
          Column({ space: 5 }) {
            Image($r("app.media.icon_save")).width(36).aspectRatio(1)
            Text("保存").fontSize(16).fontColor("#333333")
          }
          .padding({
            left: 16,
            right: 16,
            top: 8,
            bottom: 8
          })
          .onClick(() => {
            this.save()
          })
        }.layoutWeight(1)

        Stack() {
          Column({ space: 5 }) {
            Image($r("app.media.icon_paste")).width(36).aspectRatio(1)
            Text("短信").fontSize(16).fontColor("#333333")
          }
          .padding({
            left: 16,
            right: 16,
            top: 8,
            bottom: 8
          })
          .onClick(() => {
            this.startMsgPage()
          })
        }.layoutWeight(1)



      }.alignRules({
        start: { anchor: '__container__', align: HorizontalAlign.Start },
        end: { anchor: '__container__', align: HorizontalAlign.End },
        bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}