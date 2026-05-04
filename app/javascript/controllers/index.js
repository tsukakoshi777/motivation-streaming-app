// app/javascript/controllers/index.js
import { application } from "./application"

// Eager load all controllers
import LoadingController from "./loading_controller"
application.register("loading", LoadingController)