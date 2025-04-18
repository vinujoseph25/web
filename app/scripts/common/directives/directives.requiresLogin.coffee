###
# Copyright (c) 2013-2018 the original author or authors.
#
# Licensed under the MIT License (the "License");
# you may not use this file except in compliance with the License. 
# You may obtain a copy of the License at
#
#     http://www.opensource.org/licenses/mit-license.php
#
# Unless required by applicable law or agreed to in writing, 
# software distributed under the License is distributed on an 
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
# either express or implied. See the License for the specific 
# language governing permissions and limitations under the License. 
###

# Directive that hides an element unless authentication 
# is enabled and the user is logged in
babbleDirectives.directive 'requiresLogin', (userService) ->
    {
        restrict: 'CA'
        link: (scope, element, attrs) ->
            $(element).hide() unless userService.authEnabled and userService.isLoggedIn()

            scope.$watch userService.isLoggedIn, ->
                if userService.authEnabled and userService.isLoggedIn() 
                    $(element).show()
                else
                    $(element).hide()
    }
