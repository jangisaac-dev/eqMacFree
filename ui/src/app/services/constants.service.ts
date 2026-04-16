import { Injectable } from '@angular/core'

@Injectable({
  providedIn: 'root'
})
export class ConstantsService {
  readonly GITHUB_OWNER = 'jangisaac-dev'
  readonly REPO_NAME = 'eqMacFree'
  readonly DOMAIN = 'github.com'
  readonly REPO_URL = new URL(`https://${this.DOMAIN}/${this.GITHUB_OWNER}/${this.REPO_NAME}`)
  readonly FAQ_URL = new URL(`${this.REPO_URL.toString()}#readme`)
  readonly FEATURES_URL = new URL(`${this.REPO_URL.toString()}#available-now`)
  readonly BUG_REPORT_URL = new URL(`${this.REPO_URL.toString()}/issues/new/choose`)
  readonly ROADMAP_URL = new URL(`${this.REPO_URL.toString()}/blob/main/docs/roadmap/lock-feature-backlog.md`)
  readonly FEATURE_REQUEST_URL = new URL(`${this.REPO_URL.toString()}/issues/new/choose`)
}
