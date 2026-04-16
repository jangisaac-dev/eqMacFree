import { Component, Inject } from '@angular/core'
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog'

import { ApplicationService } from '../../services/app.service'

export interface LockStateDialogData {
  title: string
  description: string
  roadmapUrl: URL
  issueUrl: URL
}

@Component({
  selector: 'eqm-lock-state-dialog',
  templateUrl: './lock-state-dialog.component.html',
  styleUrls: [ './lock-state-dialog.component.scss' ]
})
export class LockStateDialogComponent {
  constructor (
    public dialogRef: MatDialogRef<LockStateDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: LockStateDialogData,
    private readonly app: ApplicationService
  ) {
  }

  openRoadmap () {
    this.app.openURL(this.data.roadmapUrl)
    this.dialogRef.close()
  }

  openIssueTracker () {
    this.app.openURL(this.data.issueUrl)
    this.dialogRef.close()
  }
}
