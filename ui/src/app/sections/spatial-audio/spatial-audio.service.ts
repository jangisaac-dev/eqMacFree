import { Injectable } from '@angular/core'
import { DataService } from 'src/app/services/data.service'
import { Subject } from 'rxjs'

export type SpatialAudioPreset = 'cinema' | 'music' | 'voice' | 'studio' | 'live' | 'gaming'
export interface SpatialAudioState {
  enabled: boolean
  preset: SpatialAudioPreset
}

@Injectable({
  providedIn: 'root'
})
export class SpatialAudioService extends DataService {
  route = `${this.route}/settings`
  stateChanged = new Subject<SpatialAudioState>()
  state: SpatialAudioState = {
    enabled: false,
    preset: 'music'
  }

  async syncState (): Promise<SpatialAudioState> {
    const [ enabled, preset ] = await Promise.all([
      this.getEnabled(),
      this.getPreset()
    ])
    this.state = { enabled, preset }
    this.stateChanged.next(this.state)
    return this.state
  }

  async getEnabled (): Promise<boolean> {
    const { spatialAudioEnabled } = await this.request({ method: 'GET', endpoint: '/spatial-audio-enabled' })
    return spatialAudioEnabled
  }

  async setEnabled (spatialAudioEnabled: boolean) {
    await this.request({ method: 'POST', endpoint: '/spatial-audio-enabled', data: { spatialAudioEnabled } })
    this.state = {
      ...this.state,
      enabled: spatialAudioEnabled
    }
    this.stateChanged.next(this.state)
  }

  async getPreset (): Promise<SpatialAudioPreset> {
    const { spatialAudioPreset } = await this.request({ method: 'GET', endpoint: '/spatial-audio-preset' })
    return spatialAudioPreset
  }

  async setPreset (spatialAudioPreset: SpatialAudioPreset) {
    await this.request({ method: 'POST', endpoint: '/spatial-audio-preset', data: { spatialAudioPreset } })
    this.state = {
      ...this.state,
      preset: spatialAudioPreset
    }
    this.stateChanged.next(this.state)
  }
}
