#
# Sample Config File
#
# This file is a sample configuration file for Babble.  It is configured for a local instance
# of the Babble REST API (babble-service), so it can be used as-is.
# 
# Post-build, this file will be found in the `_public/js/conf/` folder.
# Babble attempts to load a file named `configService.js`, so this file must be renamed or
# copied prior to use.
#
# By default, the development task `gulp server` will copy this file if `configService.js` does not
# already exist.
#
# This configService depends on the 'commonConfigService', found in `scripts/common/services`.
# Most of the configuration is done in that service, and this service merely wraps it, providing
# environment-specific configs.  This facilitates deploying multiple Babble environments, 
# where only the endpoints are different.
#
babbleServices.factory 'configService', (commonConfigService) ->

    # List of neighboring Babble instances
    # Used for:
    #   1) Push Dashboard to Environment (e.g. push from Dev to Prod)
    #   2) Data Source Proxying
    #
    # "name": Display Name.
    # "serviceUrl": Destination service endpoint.
    # "requiresAuth": Must match the configuration on the destination service.
    # "canPush": If true, enables pushing Dashboard from this instance to the destination instance.
    #
    # change babbleEnv to Dev or Prod
    # babbleEnv = 'Prod' 
    babbleEnv = 'Dev' 
    host = window.location.origin+'/api';
    babbleEnvironments = [
        {
            name: 'Prod'
            serviceUrl: host
            requiresAuth: true
            canPush: true
        }
        {
            name: 'Dev'
            serviceUrl: 'http://localhost:8077'
            requiresAuth: true
            canPush: true
        }
    ]

    # Convert babbleEnvironments into the correct format for property options
    proxyOptions = _.reduce babbleEnvironments, (options, environment) ->
        options[environment.name] = { value: environment.serviceUrl }
        return options
    , {}

    exports = 
        # Babble-service endpoint
        restServiceUrl: proxyOptions[babbleEnv].value

        authentication:
            # Enable or disable authentication
            # Should match the babble-service configuration
            enable: true

            # Message displayed when logging in.  Set to null/blank to disable
            loginMessage: 'Please login using your username and password.'

            # If true, the user's password will be encrypted and cached in the browser
            # This allows data sources to authenticate with the current user's credentials
            cacheEncryptedPassword: false

        # Analytics settings
        analytics:
            # Enable or disable analytic tracking for dashboards
            enable: false

        # Logging settings
        logging:
            enableDebug: false

        # New Users
        newUser:
            # Enables/disables welcome message for new users
            enableMessage: true

        
        # List of neighboring Babble instances
        babbleEnvironments: babbleEnvironments

        # Changelog location, displayed on the home page footer
        #changelogLink: 'https://.../CHANGELOG.md'

        # Overrides for Dashboard properties
        #
        # 1) Provide environment-specific default values, e.g. default URLs for Data Sources
        # 2) Set proxy options for Data Sources
        #
        dashboard:
            properties:
                dataSources:
                    options:
                        babbleData:
                            properties:
                                url:
                                    options: proxyOptions
                        graphite:
                            properties:
                                url:
                                    # The default Graphite hostname, so it does not need to be specified in each Dashboard
                                    # (Remove if there is no appropriate default)
                                    default: 'http://sampleGraphiteHost:80'
                                proxy:
                                    options: proxyOptions
                        json:
                            properties:
                                proxy:
                                    options: proxyOptions
                        prometheus:
                            properties:
                                proxy:
                                    options: proxyOptions
                        splunk:
                            properties:
                                host:
                                    # The default Splunk hostname, so it does not need to be specified in each Dashboard
                                    # (Remove if there is no appropriate default)
                                    default: 'splunk'
                                proxy:
                                    options: proxyOptions

        # Add additional logos to the Dashboard Sidebar 
        dashboardSidebar:
            footer:
                logos: [{
                    title: 'Babble'
                    src: '/img/favicon32.png'
                    href: '/'
                }]

    # Merge overrides with commonConfigService
    # Settings in this file will override/extend those in the commonConfigService
    merged = _.merge(commonConfigService, exports, _["default"])

    # Add a custom welcome message to the Help page
    # Additional messages can be added, e.g. support mailing list
    merged.help[0].messages = [{
        type: 'info',
        html: 'Welcome to Babble!',
        icon: 'fa-info-circle'
    }];

    return merged;
