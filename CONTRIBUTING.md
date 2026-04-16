## Contribution

eqMacFree accepts focused pull requests against the public repository. Please start by opening or reviewing a GitHub issue so the work stays aligned with the public roadmap and current launch phase.

For larger changes, describe the intended scope before implementation so launch-critical work and future lock-feature reimplementation work do not drift together.

## Development
Fork the repository, then run these commands in Terminal.app:

``` 
git clone https://github.com/jangisaac-dev/eqMacFree.git
cd eqMacFree/
```

### Web User Interface
If you want to run the web-based user interface locally, follow these steps:

#### Prerequisites
Install [Node.js](https://nodejs.org/en/) LTS version preferrably using [NVM](https://github.com/nvm-sh/nvm#installing-and-updating)

Install [Yarn](https://classic.yarnpkg.com/en/) v1 globally: `npm i -g yarn` (the project uses [Yarn Workspaces](https://classic.yarnpkg.com/en/docs/workspaces/))

#### Building and running the Web UI
1. Run `yarn` from the root directory of the Monorepo
2. Go into the ui/ directory by `cd ui/`
3. Start local development server with `yarn start`

### Native app + driver
#### Prerequisites

1. Download [Xcode](https://apps.apple.com/us/app/xcode/id497799835?mt=12)
2. Install [CocoaPods](https://cocoapods.org/) by `sudo gem install cocoapods`

#### Building and running the app

1. Go into the native/app directory from root of the repo by: `cd native/`
2. Install Cocoapod dependencies: `pod install`
3. Open the Xcode workspace: `open eqMac.xcworkspace`
4. Launch the app in debug mode by running the **App - Debug** scheme:
<img width="512" src="https://user-images.githubusercontent.com/8472525/83069640-279c1100-a062-11ea-85a7-45aa5253771b.png"/>
