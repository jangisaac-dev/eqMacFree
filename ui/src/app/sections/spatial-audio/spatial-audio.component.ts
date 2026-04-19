import { Component, HostBinding, OnDestroy, OnInit } from '@angular/core'
import { ApplicationService } from '../../services/app.service'
import { UIService } from '../../services/ui.service'
import { SpatialAudioPreset, SpatialAudioService } from './spatial-audio.service'
import { Subscription } from 'rxjs'
import { MatDialog, MatDialogRef } from '@angular/material/dialog'
import { OptionsDialogComponent } from '../../components/options-dialog/options-dialog.component'
import { Options } from '../../components/options/options.component'

interface SpatialAudioPresetOption {
  id: SpatialAudioPreset
  label: string
}

@Component({
  selector: 'eqm-spatial-audio',
  templateUrl: './spatial-audio.component.html',
  styleUrls: [ './spatial-audio.component.scss' ]
})
export class SpatialAudioComponent implements OnInit, OnDestroy {
  toolbarHeight = 30
  presetsHeight = 46
  enabled = false
  show = true
  preset: SpatialAudioPreset = 'music'
  presetOptions: SpatialAudioPresetOption[] = [
    { id: 'music', label: 'Music (Balanced)' },
    { id: 'cinema', label: 'Cinema (Wide)' },
    { id: 'voice', label: 'Voice (Clear)' },
    { id: 'studio', label: 'Studio (Subtle)' },
    { id: 'live', label: 'Live (Airy)' },
    { id: 'gaming', label: 'Gaming (Front)' }
  ]

  settingsDialog?: MatDialogRef<OptionsDialogComponent>

  @HostBinding('style.min-height.px') get height () {
    return this.toolbarHeight + (this.show ? this.presetsHeight : 0)
  }

  @HostBinding('style.max-height.px') get maxHeight () {
    return this.toolbarHeight + (this.show ? this.presetsHeight : 0)
  }

  constructor (
    public service: SpatialAudioService,
    public app: ApplicationService,
    public ui: UIService,
    public dialog: MatDialog
  ) {}

  private stateChangedSubscription: Subscription

  async ngOnInit () {
    const [ state, uiSettings ] = await Promise.all([
      this.service.syncState(),
      this.ui.getSettings()
    ])
    this.enabled = state.enabled
    this.preset = state.preset
    this.show = uiSettings.showSpatialAudio ?? true
    this.setupEvents()
  }

  setupEvents () {
    this.stateChangedSubscription = this.service.stateChanged.subscribe(state => {
      this.enabled = state.enabled
      this.preset = state.preset
    })
  }

  get summaryLabel () {
    return this.enabled ? this.presetLabel(this.preset) : 'Off'
  }

  get selectedPresetOption () {
    return this.presetOptions.find(option => option.id === this.preset)
  }

  toggleVisibility () {
    this.show = !this.show
    this.ui.setSettings({ showSpatialAudio: this.show })
  }

  async setEnabled (enabled: boolean) {
    this.enabled = enabled
    await this.service.setEnabled(enabled)
  }

  async selectPreset (preset: SpatialAudioPreset) {
    if (!this.app.enabled || !this.enabled || this.preset === preset) {
      return
    }
    this.preset = preset
    await this.service.setPreset(preset)
  }

  async selectPresetOption (option: SpatialAudioPresetOption) {
    await this.selectPreset(option.id)
  }

  openSettings () {
    const options: Options = [
      [ { type: 'label', label: 'Spatial Audio Presets' } ],
      [ { type: 'label', label: 'Music (Balanced): keeps the original mix most intact and adds only light width.' } ],
      [ { type: 'label', label: 'Cinema (Wide): pushes the stereo image wider and makes the space effect more obvious.' } ],
      [ { type: 'label', label: 'Voice (Clear): keeps dialogue and lead vocals more forward with the lightest wet mix.' } ],
      [ { type: 'label', label: 'Studio (Subtle): near-field image with the gentlest spatial shaping for reference listening.' } ],
      [ { type: 'label', label: 'Live (Airy): lifts the stage and ambience more aggressively for concert-like spread.' } ],
      [ { type: 'label', label: 'Gaming (Front): keeps cues forward and separated with tighter left/right imaging.' } ]
    ]

    this.settingsDialog = this.dialog.open(OptionsDialogComponent, {
      data: {
        title: 'Spatial Audio Settings',
        options
      }
    })
  }

  presetLabel (preset: SpatialAudioPreset) {
    return ({
      cinema: 'Wide',
      music: 'Balanced',
      voice: 'Clear',
      studio: 'Subtle',
      live: 'Airy',
      gaming: 'Front'
    })[preset]
  }

  ngOnDestroy () {
    this.stateChangedSubscription?.unsubscribe()
  }
}
