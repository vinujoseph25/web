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

#
# EncryptString controller -- for modal dialog
#
babbleApp.controller 'EncryptStringController', ($scope, $uibModalInstance, cryptoService, configService) ->

    $scope.fields = {}

    $scope.encrypt = ->
        return if _.isEmpty $scope.fields.value
        cryptoService.encrypt($scope.fields.value).then (result) ->
            $scope.fields.encryptedValue = result

    $scope.cancel = ->
        $uibModalInstance.dismiss('cancel')
