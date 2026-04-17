import {
  Component,
  OnInit,
  ViewChild,
  AfterContentInit,
  HostListener
} from '@angular/core'
import { UtilitiesService } from './services/utilities.service'
import { UIService } from './services/ui.service'
import { FadeInOutAnimation, FromTopAnimation } from '@eqmac/components'
import { MatDialog, MatDialogRef } from '@angular/material/dialog'
import { TransitionService } from './services/transitions.service'
import { AnalyticsService } from './services/analytics.service'
import { ApplicationService } from './services/app.service'
import { ConstantsService } from './services/constants.service'
import { SettingsService, IconMode } from './sections/settings/settings.service'
import { ToastService } from './services/toast.service'
import { OptionsDialogComponent } from './components/options-dialog/options-dialog.component'
import { Option, Options } from './components/options/options.component'
import { HeaderComponent } from './sections/header/header.component'
import { VolumeBoosterBalanceComponent } from './sections/volume/booster-balance/volume-booster-balance.component'
import { EqualizersComponent } from './sections/effects/equalizers/equalizers.component'
import { OutputsComponent } from './sections/outputs/outputs.component'

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: [ './app.component.scss' ],
  animations: [ FadeInOutAnimation, FromTopAnimation ]
})

export class AppComponent implements OnInit, AfterContentInit {
  @ViewChild('container', { static: true }) container
  @ViewChild('header', { static: true }) header: HeaderComponent
  @ViewChild('volumeBoosterBalance', { static: false }) volumeBoosterBalance: VolumeBoosterBalanceComponent
  @ViewChild('equalizers', { static: false }) equalizers: EqualizersComponent
  @ViewChild('outputs', { static: false }) outputs: OutputsComponent

  loaded = false
  animationDuration = 500
  animationFps = 30

  showDropdownSections = {
    settings: false,
    help: false
  }

  private containerWidth = 400
  private containerHeight = 400
  get containerStyle () {
    const style: any = {}

    style.width = `${this.containerWidth / this.ui.scale}px`
    style.height = `${this.containerHeight / this.ui.scale}px`
    style.transform = `scale(${this.ui.scale})`

    const cdkOverlays = document.getElementsByClassName('cdk-overlay-pane')
    for (let i = 0; i < cdkOverlays.length; i++) {
      cdkOverlays[i].setAttribute('style', `transform: scale(${this.ui.scale.toFixed(2)}); width: ${Math.round(90 / this.ui.scale)}vw`)
    }
    return style
  }

  constructor (
    public utils: UtilitiesService,
    public ui: UIService,
    public dialog: MatDialog,
    public transitions: TransitionService,
    public analytics: AnalyticsService,
    public app: ApplicationService,
    public CONST: ConstantsService,
    public settings: SettingsService,
    public toast: ToastService
  ) {
    this.app.ref = this
  }

  get minHeight () {
    const divider = 3

    const {
      volumeFeatureEnabled, balanceFeatureEnabled,
      equalizersFeatureEnabled,
      outputFeatureEnabled
    } = this.ui.settings
    let minHeight = this.header.height + divider +
      ((volumeFeatureEnabled || balanceFeatureEnabled) ? (this.volumeBoosterBalance.height + divider) : 0) +
      (equalizersFeatureEnabled ? (this.equalizers.height + divider) : 0) +
      (outputFeatureEnabled ? this.outputs.height : 0)

    const dropdownSection = document.getElementById('dropdown-section')
    if (dropdownSection) {
      const dropdownHeight = dropdownSection.offsetHeight + this.header.height + divider
      if (dropdownHeight > minHeight) {
        minHeight = dropdownHeight
      }
    }

    return minHeight
  }

  get minWidth () {
    return 400
  }

  get maxHeight () {
    const divider = 3

    const {
      volumeFeatureEnabled, balanceFeatureEnabled,
      equalizersFeatureEnabled,
      outputFeatureEnabled
    } = this.ui.settings
    let maxHeight = this.header.height + divider +
      ((volumeFeatureEnabled || balanceFeatureEnabled) ? (this.volumeBoosterBalance.height + divider) : 0) +
      (equalizersFeatureEnabled ? (this.equalizers.maxHeight + divider) : 0) +
      (outputFeatureEnabled ? this.outputs.height : 0)

    const dropdownSection = document.getElementById('dropdown-section')
    if (dropdownSection) {
      const dropdownHeight = dropdownSection.offsetHeight + this.header.height + divider
      if (dropdownHeight > maxHeight) {
        maxHeight = dropdownHeight
      }
    }

    return maxHeight
  }

  async ngOnInit () {
    await this.sync()
    await this.fixUIMode()
    this.startDimensionsSync()
    await this.setupPrivacy()
  }

  async setupPrivacy () {
    const [ uiSettings ] = await Promise.all([
      this.ui.getSettings()
    ])

    if (!this.CONST.TELEMETRY_ENABLED && !this.CONST.CRASH_REPORTING_ENABLED) {
      if (typeof uiSettings.privacyFormSeen !== 'boolean') {
        await Promise.all([
          this.ui.setSettings({
            privacyFormSeen: true,
            doCollectTelemetry: false
          }),
          this.settings.setDoCollectCrashReports({
            doCollectCrashReports: false
          })
        ])
      }
      return
    }

    if (typeof uiSettings.privacyFormSeen !== 'boolean') {
      let doCollectTelemetry = uiSettings.doCollectTelemetry ?? false
      let doCollectCrashReports = await this.settings.getDoCollectCrashReports()
      let saving = false
      const privacyOptions: Options = [
        [ { type: 'label', label: 'Privacy' } ],
        [ {
          type: 'label', label: `eqMacFree respects your privacy
and lets you choose what anonymous data to share with the maintainers.
That data helps improve reliability and prioritize public roadmap work.`
        } ]
      ]

      if (this.CONST.TELEMETRY_ENABLED) {
        const doCollectTelemetryOption: Option = {
          type: 'checkbox',
          label: 'Send anonymous usage telemetry',
          tooltip: `
eqMacFree can collect anonymous usage data such as:

• macOS version
• app and UI version
• country derived from anonymized IP data

This helps maintainers understand how the public app is used.
`,
          tooltipAsComponent: true,
          value: doCollectTelemetry,
          isEnabled: () => !saving,
          toggled: doCollect => {
            doCollectTelemetry = doCollect
          }
        }
        privacyOptions.push([ doCollectTelemetryOption ])
      }

      if (this.CONST.CRASH_REPORTING_ENABLED) {
        const doCollectCrashReportsOption: Option = {
          type: 'checkbox',
          label: 'Send anonymous crash reports',
          tooltip: `
eqMacFree can send anonymized crash reports
to the maintainers if the app crashes.
This helps us diagnose stability problems
and improve the public release.
`,
          tooltipAsComponent: true,
          value: doCollectCrashReports,
          isEnabled: () => !saving,
          toggled: doCollect => {
            doCollectCrashReports = doCollect
          }
        }
        privacyOptions.push([ doCollectCrashReportsOption ])
      }

      const privacyDialog: MatDialogRef<OptionsDialogComponent> = this.dialog.open(OptionsDialogComponent, {
        hasBackdrop: true,
        disableClose: true,
        data: {
          options: [
            ...privacyOptions,
            [
              {
                type: 'button',
                label: 'Save',
                isEnabled: () => !saving,
                action: () => privacyDialog.close()
              },
              {
                type: 'button',
                label: 'Accept all',
                isEnabled: () => !saving,
                action: async () => {
                  doCollectCrashReports = this.CONST.CRASH_REPORTING_ENABLED
                  doCollectTelemetry = this.CONST.TELEMETRY_ENABLED
                  saving = true
                  await this.utils.delay(200)
                  privacyDialog.close()
                }
              }
            ]
          ] as Options
        }
      })

      await privacyDialog.afterClosed().toPromise()

      await Promise.all([
        this.ui.setSettings({
          privacyFormSeen: true,
          doCollectTelemetry
        }),
        this.settings.setDoCollectCrashReports({
          doCollectCrashReports
        })
      ])
    }

    if (this.CONST.TELEMETRY_ENABLED && uiSettings.doCollectTelemetry) {
      await this.analytics.init()
    }
  }

  async ngAfterContentInit () {
    await this.utils.delay(this.animationDuration)
    this.loaded = true
    await this.utils.delay(1000)
    this.ui.loaded()
  }

  async sync () {
    await Promise.all([
      this.getTransitionSettings()
    ])
  }

  async startDimensionsSync () {
    this.handleWindowResize()
    setInterval(() => {
      this.syncMinHeight()
      this.syncMaxHeight()
    }, 1000)
  }

  private previousMinHeight: number
  async syncMinHeight () {
    if (!this.previousMinHeight) {
      this.previousMinHeight = this.minHeight
      await this.ui.setMinHeight({ minHeight: this.minHeight })
      return
    }

    const diff = this.minHeight - this.previousMinHeight
    this.previousMinHeight = this.minHeight
    if (diff !== 0) {
      this.ui.onMinHeightChanged.emit()
      await this.ui.setMinHeight({ minHeight: this.minHeight })
    }

    if (diff < 0) {
      this.ui.changeHeight({ diff })
    }
  }

  private previousMaxHeight: number
  async syncMaxHeight () {
    if (!this.previousMaxHeight) {
      this.previousMaxHeight = this.maxHeight
      await this.ui.setMaxHeight({ maxHeight: this.maxHeight })
      return
    }

    const diff = this.maxHeight - this.previousMaxHeight
    this.previousMaxHeight = this.maxHeight
    await this.ui.setMaxHeight({ maxHeight: this.maxHeight })
    if (diff > 0) {
      // this.ui.changeHeight({ diff })
    }
  }

  private windowResizeHandlerTimer: number
  @HostListener('window:resize')
  handleWindowResize () {
    if (this.windowResizeHandlerTimer) {
      clearTimeout(this.windowResizeHandlerTimer)
    }

    this.windowResizeHandlerTimer = setTimeout(async () => {
      const [ height, width ] = await Promise.all([
        this.ui.getHeight(),
        this.ui.getWidth()
      ])

      this.containerHeight = height
      this.containerWidth = width

      setTimeout(() => {
        this.ui.dimensionsChanged.emit()
      }, 100)
    }, 100) as any
  }

  async getTransitionSettings () {
    const settings = await this.transitions.getSettings()
    this.animationDuration = settings.duration
    this.animationFps = settings.fps
  }

  toggleDropdownSection (section: string) {
    for (const key in this.showDropdownSections) {
      this.showDropdownSections[key] = key === section ? !this.showDropdownSections[key] : false
    }
  }

  openDropdownSection (section: string) {
    for (const key in this.showDropdownSections) {
      this.showDropdownSections[key] = key === section
    }
  }

  async fixUIMode () {
    const [ mode, iconMode ] = await Promise.all([
      this.ui.getMode(),
      this.settings.getIconMode()
    ])

    if (mode === 'popover' && iconMode === IconMode.dock) {
      await this.ui.setMode('window')
    }
  }

  closeDropdownSection (section: string, event?: MouseEvent) {
    // if (event && event.target && ['backdrop', 'mat-dialog'].some(e => event.target.className.includes(e))) return
    if (this.dialog.openDialogs.length > 0) return
    if (section in this.showDropdownSections) {
      this.showDropdownSections[section] = false
    }
  }
}
