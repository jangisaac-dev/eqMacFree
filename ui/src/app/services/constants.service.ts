import { Injectable } from '@angular/core'

@Injectable({
  providedIn: 'root'
})
export class ConstantsService {
  readonly GITHUB_OWNER = 'jangisaac-dev'
  readonly REPO_NAME = 'eqMacFree'
  readonly DOMAIN = 'github.com'
  readonly RAW_CONTENT_DOMAIN = 'raw.githubusercontent.com'
  readonly REPO_URL = new URL(`https://${this.DOMAIN}/${this.GITHUB_OWNER}/${this.REPO_NAME}`)
  readonly FAQ_URL = new URL(`${this.REPO_URL.toString()}#readme`)
  readonly FEATURES_URL = new URL(`${this.REPO_URL.toString()}#available-now`)
  readonly BUG_REPORT_URL = new URL(`${this.REPO_URL.toString()}/issues/new/choose`)
  readonly ROADMAP_URL = new URL(`${this.REPO_URL.toString()}/blob/main/docs/roadmap/lock-feature-backlog.md`)
  readonly FEATURE_REQUEST_URL = new URL(`${this.REPO_URL.toString()}/issues/new/choose`)
  readonly TELEMETRY_ENABLED = false
  readonly CRASH_REPORTING_ENABLED = false
  readonly RELEASE_TAG_PREFIX = 'eqmacfree-v'
  readonly STABLE_APPCAST_URL = new URL(`https://${this.RAW_CONTENT_DOMAIN}/${this.GITHUB_OWNER}/${this.REPO_NAME}/main/docs/appcast/stable.xml`)
  readonly BETA_APPCAST_URL = new URL(`https://${this.RAW_CONTENT_DOMAIN}/${this.GITHUB_OWNER}/${this.REPO_NAME}/main/docs/appcast/beta.xml`)
}
