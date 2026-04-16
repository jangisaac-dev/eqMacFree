import { Component, OnInit } from '@angular/core'
import { MatDialog } from '@angular/material/dialog'
import { Options } from 'src/app/components/options/options.component'
import { ApplicationService, Info } from 'src/app/services/app.service'
import { ConstantsService } from 'src/app/services/constants.service'
import { LockStateDialogComponent } from 'src/app/components/lock-state-dialog/lock-state-dialog.component'
import { LockStateService } from 'src/app/services/lock-state.service'
import packageJson from '../../../../package.json'
import { UIService } from '../../services/ui.service'

@Component({
  selector: 'eqm-help',
  templateUrl: './help.component.html',
  styleUrls: [ './help.component.scss' ]
})
export class HelpComponent implements OnInit {
  options: Options = [
    [
      {
        type: 'button',
        label: 'FAQ',
        action: this.faq.bind(this)
      }, {
        type: 'button',
        label: 'Volume Mixer',
        action: this.openVolumeMixerLock.bind(this)
      }, {
        type: 'button',
        label: 'Report a Bug',
        action: this.reportBug.bind(this)
      }
    ]
  ]

  constructor (
    public app: ApplicationService,
    public CONST: ConstantsService,
    public ui: UIService,
    public dialog: MatDialog,
    public lockState: LockStateService
  ) {}

  uiVersion = `${packageJson.version} (${this.ui.isLocal ? 'Local' : 'Remote'})`
  info: Info
  ngOnInit () {
    this.fetchInfo()
  }

  async fetchInfo () {
    this.info = await this.app.getInfo()
  }

  reportBug () {
    this.app.openURL(this.CONST.BUG_REPORT_URL)
  }

  faq () {
    this.app.openURL(this.CONST.FAQ_URL)
  }

  openVolumeMixerLock () {
    const definition = this.lockState.getDefinition('volume-mixer')

    this.dialog.open(LockStateDialogComponent, {
      data: {
        title: `${definition.title} · ${definition.label}`,
        description: definition.description,
        roadmapUrl: definition.roadmapUrl,
        issueUrl: definition.issueUrl
      }
    })
  }
}
