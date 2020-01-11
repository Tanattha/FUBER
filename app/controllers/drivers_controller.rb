class DriversController < ApplicationController

  patch "/driver/trips/:id/:status/edit" do 
    trip = Trip.find(params[:id])
    trip.status = params[:status]
    trip.save 
    
    if params[:status] == "completed" || params[:status] =="canceled"
      redirect "/driver/dashboard"
    else
      redirect "/driver/trips/#{params[:id]}"
    end
  end

  # GET: /drivers
  get "/driver/dashboard" do
    @stylesheet_link = "/stylesheets/passengers/dashboard.css"
    @driver = authenticate_user
    map = GMAPS.directions(@driver.current_location,"181 mansion st poughkeepsie ny",mode: 'driving',alternatives: false)
    @driver_coord = map[0][:legs][0][:start_location]

    @trips = @driver.trips.detect{|trip| trip.status == "pending"}
    erb :"/drivers/dashboard.html"
  end

  post "/driver/dashboard/notification/:id/dismiss" do
    driver = authenticate_user
    trip = driver.trips.detect {|trip| trip.id == params[:id].to_i}
    
    trip.driver = nil;
    trip.save
    driver.reload

    redirect "/driver/dashboard"
  end

  post "/driver/dashboard/notification/:id/accept" do
    driver = authenticate_user
    trip = driver.trips.detect {|trip| trip.id == params[:id].to_i}
  
    trip.status = "in route" 
    trip.save
    driver.reload
    redirect "/driver/trips/#{params[:id]}"
  end

  get "/driver/trips/:id" do 
    @driver = authenticate_user
    if params[:id] == "no_active_trips"
       redirect "/driver/dashboard"
    else  
      @trip = Trip.find_by(id: params[:id])
      @leg_info = @driver.distance_from(@trip.from)
      @instructions = @driver.driving_instructions

      erb :"/drivers/show_trip.html"
    end
    
  end


  get "/driver/trips" do 
    @driver = authenticate_user
    erb :"/drivers/trips.html"
  end













  # GET: /drivers/new
  get "/drivers/new" do
    erb :"/drivers/new.html"
  end

  # POST: /drivers
  post "/drivers" do
    redirect "/drivers"
  end

  # GET: /drivers/5
  get "/drivers/:id" do
    erb :"/drivers/show.html"
  end

  # GET: /drivers/5/edit
  get "/drivers/:id/edit" do
    erb :"/drivers/edit.html"
  end

  # PATCH: /drivers/5
  patch "/drivers/:id" do
    redirect "/drivers/:id"
  end

  # DELETE: /drivers/5/delete
  delete "/drivers/:id/delete" do
    redirect "/drivers"
  end


  helpers do 

    def authenticate_user
      redirect "/login" if !Helpers.logged_in?(session)
      redirect "/not-found" if Helpers.current_user(session).class.to_s != "Driver"
      Helpers.current_user(session)
    end
  
  end




end
