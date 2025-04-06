#
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
#

'use strict'

###*
 # @ngdoc function
 # @name babbleApp.controller:ResetPasswordController
 # @description
 # # ResetPasswordController
 # Controller for the reset password page
###
angular.module('babbleApp')
  .controller 'ResetPasswordController', ($scope, $location, userService, $window) ->
    $scope.user = {}
    $scope.resetSent = false
    $scope.resetError = false
    $scope.resetErrorMessage = ''

    # Redirect if already logged in
    if userService.isLoggedIn()
        $location.path '/'
    
    $scope.sendResetLink = ->
      return if !$scope.user.email
      
      userService.requestPasswordReset($scope.user.email)
        .then (data) ->
          # Show success message
          $scope.resetSent = true
          $scope.resetError = false
        .catch (error) ->
          $scope.resetError = true
          $scope.resetErrorMessage = error.message || 'Could not process your request. Please try again.'
    
    $scope.backToLogin = ->
      $location.path '/login'