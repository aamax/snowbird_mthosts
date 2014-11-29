angular.module("mthosts", ["ngResource",
                           "ng-rails-csrf",
                           "UserServices",
                           'md5',
                           'ui-gravatar',
                           "ShiftTypeServices",
                           'ShiftServices'])

.controller("ShiftTypeCtrl", ["$scope", "$resource", "shiftTypeResource", ShiftTypeCtrl])
.controller("ShiftTypeModalCtrl", ["$scope", "$resource", "shiftTypeResource", ShiftTypeModalCtrl])
.controller("SurveyCtrl", ["$scope", "$resource", "$http", SurveyCtrl])
.controller("ShiftBuilderCtrl", ["$scope", ShiftBuilderCtrl])
