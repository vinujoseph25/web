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
 # @name babbleApp.controller:ChangePasswordController
 # @description
 # # ChangePasswordController
 # Controller for the change password page
###
angular.module('babbleApp')
  .controller 'ChangePasswordController', ($scope, $location, userService, $window, $timeout) ->
    # Initialize variables
    $scope.passwordData = 
      password: ''
      confirmPassword: ''
    
    $scope.passwordChanged = false
    $scope.passwordError = false
    $scope.passwordErrorMessage = ''
    $scope.passwordStrength = ''
    $scope.passwordsMatch = false
    
    # Password requirement flags
    $scope.hasMinLength = false
    $scope.hasUppercase = false
    $scope.hasLowercase = false
    $scope.hasNumber = false
    $scope.hasSpecial = false
    
    # Initialize the controller
    initialize = ->
    # Redirect to reset password page if no token is found or user is not logged in
    if !(userService.isLoggedIn() || userService.hasResetToken())
        $location.path '/reset-password'  
    
    # Check password strength
    $scope.checkPasswordStrength = ->
      password = $scope.passwordData.password
      
      # Check requirements
      $scope.hasMinLength = password.length >= 8
      $scope.hasUppercase = /[A-Z]/.test(password)
      $scope.hasLowercase = /[a-z]/.test(password)
      $scope.hasNumber = /[0-9]/.test(password)
      $scope.hasSpecial = /[^A-Za-z0-9]/.test(password)
      
      # Calculate strength
      metRequirements = [
        $scope.hasMinLength,
        $scope.hasUppercase,
        $scope.hasLowercase, 
        $scope.hasNumber,
        $scope.hasSpecial
      ].filter((req) -> req).length
      
      if metRequirements <= 2
        $scope.passwordStrength = 'weak'
      else if metRequirements <= 4
        $scope.passwordStrength = 'medium'
      else
        $scope.passwordStrength = 'strong'
        
      # Also check match if confirm password is entered
      if $scope.passwordData.confirmPassword
        $scope.checkPasswordMatch()
    
    # Check if passwords match
    $scope.checkPasswordMatch = ->
      if $scope.passwordData.password && $scope.passwordData.confirmPassword
        $scope.passwordsMatch = $scope.passwordData.password == $scope.passwordData.confirmPassword
      else
        $scope.passwordsMatch = false
    
    $scope.changePassword = ->
      console.log 'changePassword called'
      
      # Validate passwords
      if !$scope.passwordData.password
        $scope.passwordError = true
        $scope.passwordErrorMessage = 'Please enter a new password'
        return
        
      if $scope.passwordData.password != $scope.passwordData.confirmPassword
        $scope.passwordError = true
        $scope.passwordErrorMessage = 'Passwords do not match'
        return
        
      if $scope.passwordStrength == 'weak'
        $scope.passwordError = true
        $scope.passwordErrorMessage = 'Password is too weak. Please use a stronger password.'
        return
      
      # Call service to change password
      userService.changePassword($scope.passwordData.password)
        .then (data) ->
          # Show success message
          $scope.passwordChanged = true
          $scope.passwordError = false
          console.log 'Password changed successfully'
        .catch (error) ->
          $scope.passwordError = true
          $scope.passwordErrorMessage = error.message || 'Could not change password. Please try again.'
          console.error 'Password change error:', error
    
    $scope.goToLogin = ->
      $location.path '/login'
      
    # Initialize the controller with a timeout to ensure DOM is ready
    $timeout initialize, 0