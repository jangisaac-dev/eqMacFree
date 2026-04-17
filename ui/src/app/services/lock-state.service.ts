import { Injectable } from '@angular/core'

import { ConstantsService } from './constants.service'

export type LockFeatureKey =
  | 'spatial-audio'
  | 'volume-mixer'
  | 'spectrum-analyzer'
  | 'expert-eq'
  | 'audiounit-hosting'

export interface LockStateDefinition {
  key: LockFeatureKey
  label: string
  title: string
  priority: number
  description: string
  roadmapUrl: URL
  issueUrl: URL
}

@Injectable({
  providedIn: 'root'
})
export class LockStateService {
  private readonly definitions: Record<LockFeatureKey, LockStateDefinition> = {
    'spatial-audio': {
      key: 'spatial-audio',
      label: 'Lock',
      title: 'Spatial Audio',
      priority: 1,
      description: 'This feature is not included in the current eqMacFree public build. It is the first planned former-Pro feature reimplementation target.',
      roadmapUrl: this.CONST.ROADMAP_URL,
      issueUrl: this.CONST.FEATURE_REQUEST_URL
    },
    'volume-mixer': {
      key: 'volume-mixer',
      label: 'Lock',
      title: 'Volume Mixer',
      priority: 2,
      description: 'This feature is not included in the current eqMacFree public build. It is planned as future public roadmap work.',
      roadmapUrl: this.CONST.ROADMAP_URL,
      issueUrl: this.CONST.FEATURE_REQUEST_URL
    },
    'spectrum-analyzer': {
      key: 'spectrum-analyzer',
      label: 'Lock',
      title: 'Spectrum Analyzer',
      priority: 3,
      description: 'This feature is not included in the current eqMacFree public build. It remains planned public roadmap work.',
      roadmapUrl: this.CONST.ROADMAP_URL,
      issueUrl: this.CONST.FEATURE_REQUEST_URL
    },
    'expert-eq': {
      key: 'expert-eq',
      label: 'Lock',
      title: 'Expert EQ',
      priority: 4,
      description: 'This feature is not included in the current eqMacFree public build. It remains planned public roadmap work.',
      roadmapUrl: this.CONST.ROADMAP_URL,
      issueUrl: this.CONST.FEATURE_REQUEST_URL
    },
    'audiounit-hosting': {
      key: 'audiounit-hosting',
      label: 'Lock',
      title: 'AudioUnit Hosting',
      priority: 5,
      description: 'This feature is not included in the current eqMacFree public build. It remains planned public roadmap work.',
      roadmapUrl: this.CONST.ROADMAP_URL,
      issueUrl: this.CONST.FEATURE_REQUEST_URL
    }
  }

  constructor (private readonly CONST: ConstantsService) {}

  getDefinition (key: LockFeatureKey): LockStateDefinition {
    return this.definitions[key]
  }

  listDefinitions (): LockStateDefinition[] {
    return Object.values(this.definitions)
      .sort((left, right) => left.priority - right.priority)
  }
}
