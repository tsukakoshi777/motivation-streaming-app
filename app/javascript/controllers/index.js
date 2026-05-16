// app/javascript/controllers/index.js
import { application } from "./application"

// Eager load all controllers
import LoadingController from "./loading_controller"
import GoalSearchController from "./goal_search_controller"
import ChartController from "./chart_controller" 

application.register("loading", LoadingController)
application.register("goal-search", GoalSearchController)
application.register("chart", ChartController) 