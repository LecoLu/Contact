import { AbilityConstant, UIAbility, Want } from "@kit.AbilityKit";
import { window } from "@kit.ArkUI";

interface Storage {
  ShareUIAbilityWant: Want
}

export default class ShareUIAbility extends UIAbility {

  private storageWant: Want = {}

  onCreate(want: Want, _: AbilityConstant.LaunchParam): void {
    this.storageWant = want;
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    let para: Storage = { ShareUIAbilityWant: this.storageWant };
    let storage = new LocalStorage(para);
    windowStage.loadContent('pages/Index', storage);
  }
}
