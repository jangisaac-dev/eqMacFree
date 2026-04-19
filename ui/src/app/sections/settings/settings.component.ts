import { ChangeDetectorRef, Component, OnDestroy, OnInit } from '@angular/core'
import { CheckboxOption, ButtonOption, Options, SelectOption, DividerOption, FlatSliderOption, LabelOption, ValueScreenOption } from 'src/app/components/options/options.component'
import { SettingsService, IconMode } from './settings.service'
import { ApplicationService } from '../../services/app.service'
import { MatDialog } from '@angular/material/dialog'
import { ConfirmDialogComponent } from '../../components/confirm-dialog/confirm-dialog.component'
import { StatusItemIconType, UIService } from '../../services/ui.service'
import { AnalyticsService } from '../../services/analytics.service'
import { SemanticVersion } from '../../services/semantic-version.service'
import { OptionsDialogComponent } from '../../components/options-dialog/options-dialog.component'
import { KnobControlStyle } from '../../../../../modules/components/src'
import { SpatialAudioPreset, SpatialAudioService } from '../spatial-audio/spatial-audio.service'
import { Subscription } from 'rxjs'

@Component({
  selector: 'eqm-settings',
  templateUrl: './settings.component.html',
  styleUrls: [ './settings.component.scss' ]
})
export class SettingsComponent implements OnInit, OnDestroy {
  launchOnStartupOption: CheckboxOption = {
    type: 'checkbox',
    label: 'Launch on login',
    value: false,
    toggled: launchOnStartup => this.settingsService.setLaunchOnStartup(launchOnStartup)
  }

  replaceKnobsWithSlidersOption: CheckboxOption = {
    type: 'checkbox',
    label: 'Knobs → Sliders',
    value: false,
    toggled: replaceKnobsWithSliders => {
      this.ui.setSettings({ replaceKnobsWithSliders })
      this.app.ref.closeDropdownSection('settings')
    }
  }

  knobControlStyleOption: SelectOption<KnobControlStyle> = {
    type: 'select',
    label: 'Knob Control',
    options: [ {
      id: 'directional',
      icon: 'move'
    }, {
      id: 'rotational',
      icon: 'refresh'
    } ],
    selectedId: 'directional',
    selected: knobControlStyle => {
      this.ui.setSettings({ knobControlStyle })
    }
  }

  alwaysOnTopOption: CheckboxOption = {
    type: 'checkbox',
    label: 'Always on top',
    value: false,
    toggled: alwaysOnTop => {
      this.ui.setAlwaysOnTop({ alwaysOnTop })
    }
  }

  doCollectTelemetryOption: CheckboxOption = {
    type: 'checkbox',
    label: 'Send anonymous usage telemetry',
    tooltip: `
eqMacFree can collect anonymous usage data such as:

• macOS version
• app and UI version
• country derived from anonymized IP data

This helps maintainers understand how the public app is used.
`,
    value: false,
    toggled: doCollectTelemetry => {
      this.ui.setSettings({ doCollectTelemetry })
      if (doCollectTelemetry) {
        this.analytics.init()
      } else {
        this.analytics.deinit()
      }
    }
  }

  doCollectCrashReportsOption: CheckboxOption = {
    type: 'checkbox',
    label: 'Send anonymous crash reports',
    tooltip: `
eqMacFree can send anonymized crash reports
to the maintainers if the app crashes.
This helps us diagnose stability problems
and improve the public release.
`,
    value: false,
    toggled: doCollectCrashReports => {
      this.settingsService.setDoCollectCrashReports({
        doCollectCrashReports
      })
    }
  }

  iconModeOption: SelectOption = {
    type: 'select',
    label: 'Show Icon',
    options: [ {
      id: IconMode.dock,
      label: 'Dock'
    }, {
      id: IconMode.both,
      label: 'Both'
    }, {
      id: IconMode.statusBar,
      label: 'Status Bar'
    }, {
      id: IconMode.neither,
      label: 'Neither'
    } ],
    selectedId: IconMode.both,
    selected: async iconMode => {
      const uiMode = await this.ui.getMode()
      if (iconMode === IconMode.dock && uiMode === 'popover') {
        await this.ui.setMode('window')
      }
      await this.settingsService.setIconMode(iconMode as IconMode)
    }
  }

  uninstallOption: ButtonOption = {
    type: 'button',
    label: 'Open uninstall guide',
    hoverable: false,
    action: this.uninstall.bind(this)
  }

  updateOption: ButtonOption = {
    type: 'button',
    label: 'Check for Updates',
    action: this.update.bind(this)
  }

  autoCheckUpdatesOption: CheckboxOption = {
    type: 'checkbox',
    value: false,
    label: 'Auto Check',
    toggled: doAutoCheckUpdates => {
      this.settingsService.setDoAutoCheckUpdates({
        doAutoCheckUpdates
      })
    }
  }

  otaUpdatesOption: CheckboxOption = {
    type: 'checkbox',
    value: false,
    label: 'UI content updates',
    tooltip: `
Because the eqMacFree interface is built with web technologies,
maintainers can ship small UI-only updates separately from full desktop releases.
Use this only if you want the latest published interface content.
`,
    tooltipAsComponent: false,
    toggled: doOTAUpdates => {
      this.settingsService.setDoOTAUpdates({
        doOTAUpdates
      })
    }
  }

  betaUpdatesOption: CheckboxOption = {
    type: 'checkbox',
    value: false,
    label: 'Preview updates',
    tooltip: `
Get preview builds of recent eqMacFree changes.
This helps maintainers catch issues before broader public rollout.
`,
    toggled: doBetaUpdates => {
      this.settingsService.setDoBetaUpdates({
        doBetaUpdates
      })
    }
  }

  spatialAudioOption: CheckboxOption = {
    type: 'checkbox',
    value: false,
    label: 'Spatial Audio (Headphones)',
    tooltip: `
This is the first free public reimplementation slice of Spatial Audio in eqMacFree.
Main testing entry point is the Spatial Audio card on the main screen.
This Settings control mirrors the same experimental headphone-first state and does not claim full multichannel speaker parity.
`,
    toggled: spatialAudioEnabled => {
      this.spatialAudio.setEnabled(spatialAudioEnabled)
    }
  }

  spatialAudioPresetOption: SelectOption<SpatialAudioPreset> = {
    type: 'select',
    label: 'Spatial Audio Preset',
    options: [
      { id: 'music', label: 'Music (Balanced)' },
      { id: 'cinema', label: 'Cinema (Wide)' },
      { id: 'voice', label: 'Voice (Clear)' },
      { id: 'studio', label: 'Studio (Subtle)' },
      { id: 'live', label: 'Live (Airy)' },
      { id: 'gaming', label: 'Gaming (Front)' }
    ],
    selectedId: 'music',
    isEnabled: () => this.spatialAudioOption.value,
    selected: spatialAudioPreset => {
      this.spatialAudio.setPreset(spatialAudioPreset)
    }
  }

  statusItemIconTypeOption: SelectOption = {
    type: 'select',
    label: 'Status Icon Type',
    isEnabled: () => ([ IconMode.both, IconMode.statusBar ] as IconMode[]).includes(this.iconModeOption.selectedId as any),
    options: [ {
      id: StatusItemIconType.classic,
      label: 'Classic'
    }, {
      id: StatusItemIconType.colored,
      label: 'Colored'
    }, {
      id: StatusItemIconType.macOS,
      label: 'macOS'
    } ],
    selectedId: StatusItemIconType.classic,
    selected: async (statusItemIconType: StatusItemIconType) => {
      await this.ui.setStatusItemIconType(statusItemIconType)
    }
  }

  uiScaleLabel: LabelOption = {
    type: 'label',
    label: 'UI Scale'
  }

  setUIScaleScreenValue () {
    this.uiScaleScreen.value = `${Math.round(this.uiScaleSlider.value * 100)}%`
  }

  uiScaleSliderDebounceTimer: number
  uiScaleSlider: FlatSliderOption = {
    type: 'flat-slider',
    value: 1,
    min: 0.5,
    max: 2,
    orientation: 'horizontal',
    doubleClickToAnimateToMiddle: false,
    middle: 1,
    stickToMiddle: true,
    showMiddleNotch: true,
    scrollEnabled: false,
    userChangedValue: event => {
      this.setUIScaleScreenValue()
      this.changeRef.detectChanges()
      if (this.uiScaleSliderDebounceTimer) {
        clearTimeout(this.uiScaleSliderDebounceTimer)
      }
      this.uiScaleSliderDebounceTimer = setTimeout(() => {
        this.ui.setScale(event.value)
      }, 1000) as any
    },
    style: {
      width: '700px'
    }
  }

  uiScaleScreen: ValueScreenOption = {
    type: 'value-screen',
    value: '100%'
  }

  hideShowFeaturesOption: ButtonOption = {
    type: 'button',
    label: 'Show/Hide Features',
    action: async () => {
      const uiSettings = await this.ui.getSettings()
      const volume: CheckboxOption = {
        type: 'checkbox',
        label: 'Volume',
        value: uiSettings.volumeFeatureEnabled ?? true,
        toggled: volumeFeatureEnabled => {
          this.ui.setSettings({ volumeFeatureEnabled })
        }
      }

      const balance: CheckboxOption = {
        type: 'checkbox',
        label: 'Balance',
        value: uiSettings.balanceFeatureEnabled ?? true,
        toggled: balanceFeatureEnabled => {
          this.ui.setSettings({ balanceFeatureEnabled })
        }
      }

      const equalizers: CheckboxOption = {
        type: 'checkbox',
        label: 'Equalizers',
        value: uiSettings.equalizersFeatureEnabled ?? true,
        toggled: equalizersFeatureEnabled => {
          this.ui.setSettings({ equalizersFeatureEnabled })
        }
      }

      const output: CheckboxOption = {
        type: 'checkbox',
        label: 'Output',
        value: uiSettings.outputFeatureEnabled ?? true,
        toggled: outputFeatureEnabled => {
          this.ui.setSettings({ outputFeatureEnabled })
        }
      }
      const options: Options = [
        [ volume, balance ],
        [ this.divider ],
        [ equalizers ],
        [ this.divider ],
        [ output ]
      ]

      await this.dialog.open(OptionsDialogComponent, {
        hasBackdrop: true,
        disableClose: false,
        data: {
          options
        }
      })
    }
  }

  private readonly divider: DividerOption = { type: 'divider', orientation: 'horizontal' }
  settings: Options = [
    [ this.uiScaleLabel, this.uiScaleSlider, this.uiScaleScreen ],
    [ this.iconModeOption ],
    [ this.statusItemIconTypeOption ],
    [
      this.launchOnStartupOption,
      this.alwaysOnTopOption
    ],
    [
      this.replaceKnobsWithSlidersOption,
      this.knobControlStyleOption
    ],
    [ this.hideShowFeaturesOption ],

    [ this.spatialAudioOption, this.spatialAudioPresetOption ],

    [ this.divider ],

    [ { type: 'label', label: 'Updates' } ],
    [
      this.betaUpdatesOption,
      this.autoCheckUpdatesOption,
      this.otaUpdatesOption
    ],
    [
      this.updateOption
    ],

    [ this.divider ],

    // Privacy
    [ { type: 'label', label: 'Privacy' } ],
    [
      this.doCollectTelemetryOption,
      this.doCollectCrashReportsOption
    ],

    [ this.divider ],
    // Misc
    [ this.uninstallOption ]
  ]

  constructor (
    public settingsService: SettingsService,
    public app: ApplicationService,
    public dialog: MatDialog,
    public ui: UIService,
    public analytics: AnalyticsService,
    public spatialAudio: SpatialAudioService,
    private readonly changeRef: ChangeDetectorRef
  ) {
  }

  ngOnInit () {
    this.sync()
    this.setupEvents()
  }

  private spatialAudioStateChangedSubscription: Subscription

  setupEvents () {
    this.spatialAudioStateChangedSubscription = this.spatialAudio.stateChanged.subscribe(state => {
      this.spatialAudioOption.value = state.enabled
      this.spatialAudioPresetOption.selectedId = state.preset
      this.changeRef.detectChanges()
    })
  }

  async sync () {
    await Promise.all([
      this.syncSettings()
    ])
  }

  async syncSettings () {
    const launchOnStartup = await this.settingsService.getLaunchOnStartup()
    const iconMode = await this.settingsService.getIconMode()
    const UISettings = await this.ui.getSettings()
    const doCollectCrashReports = await this.settingsService.getDoCollectCrashReports()
    const doAutoCheckUpdates = await this.settingsService.getDoAutoCheckUpdates()
    const doOTAUpdates = await this.settingsService.getDoOTAUpdates()
    const alwaytOnTop = await this.ui.getAlwaysOnTop()
    const statusItemIconType = await this.ui.getStatusItemIconType()
    const doBetaUpdates = await this.settingsService.getDoBetaUpdates()
    const uiScale = await this.ui.getScale()
    const spatialAudioState = await this.spatialAudio.syncState()

    this.iconModeOption.selectedId = iconMode
    this.launchOnStartupOption.value = launchOnStartup
    this.replaceKnobsWithSlidersOption.value = UISettings.replaceKnobsWithSliders
    this.knobControlStyleOption.selectedId = UISettings.knobControlStyle
    this.doCollectTelemetryOption.value = UISettings.doCollectTelemetry
    this.doCollectCrashReportsOption.value = doCollectCrashReports
    this.autoCheckUpdatesOption.value = doAutoCheckUpdates
    this.otaUpdatesOption.value = doOTAUpdates
    this.alwaysOnTopOption.value = alwaytOnTop
    this.statusItemIconTypeOption.selectedId = statusItemIconType
    this.betaUpdatesOption.value = doBetaUpdates
    this.uiScaleSlider.value = uiScale
    this.spatialAudioOption.value = spatialAudioState.enabled
    this.spatialAudioPresetOption.selectedId = spatialAudioState.preset
    this.setUIScaleScreenValue()
  }

  async update () {
    this.app.update()
  }

  async uninstall () {
    this.app.uninstall()
  }

  ngOnDestroy () {
    this.spatialAudioStateChangedSubscription?.unsubscribe()
  }
}
