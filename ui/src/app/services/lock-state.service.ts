import { Injectable } from '@angular/core'

import { ConstantsService } from './constants.service'

export type LockFeatureKey = 'volume-mixer'

export interface LockStateDefinition {
  key: LockFeatureKey
  label: string
  title: string
  description: string
  roadmapUrl: URL
  issueUrl: URL
}

@Injectable({
  providedIn: 'root'
})
export class LockStateService {
  private readonly definitions: Record<LockFeatureKey, LockStateDefinition> = {
    'volume-mixer': {
      key: 'volume-mixer',
      label: 'Lock',
      title: 'Volume Mixer',
      description: 'This feature is not included in the current eqMacFree public build. It is planned as future public roadmap work.',
      roadmapUrl: this.CONST.ROADMAP_URL,
      issueUrl: this.CONST.FEATURE_REQUEST_URL
    }
  }

  constructor(private readonly CONST: ConstantsService) {}

  getDefinition(key: LockFeatureKey): LockStateDefinition {
    return this.definitions[key]
  }
}
