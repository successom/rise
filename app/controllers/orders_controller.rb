# -*- encoding : utf-8 -*-
class OrdersController < ApplicationController
   skip_before_filter :authorise, only: [:create, :new]

  # GET /orders
  # GET /orders.json
  def index
    @orders = Order.paginate page: params[:page], order: "created_at desc",
              per_page: 15

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @orders }
    end
  end

  # GET /orders/1
  # GET /orders/1.json
  def show
    @order = Order.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @order }
    end
  end

  # GET /orders/new
  # GET /orders/new.json
  def new
   # unless request.fullpath == "/orders/new"
      @cart = current_cart
      if @cart.line_items.empty?
         redirect_to store_index_path, notice: "Your cart is empty"
         return
      end

      if @order != nil
         return
      end

      @order = Order.new if @order == nil

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @order }
      end
    #end  
  end

  # GET /orders/1/edit
  def edit
    @order = Order.find(params[:id])
  end

  # POST /orders
  # POST /orders.json
  def create
    @order = Order.new(params[:order])
    @order.add_line_items_from_cart(current_cart)

    respond_to do |format|
      if @order.save
        Cart.destroy(current_cart)
        session[:cart_id] = nil
        OrderNotifier.received(@order).deliver
        format.html { redirect_to store_index_path, notice: 'Thank you for you order.' }
        format.json { render json: @order, status: :created, location: @order }
      else
        @cart = current_cart
        format.html { render action: "new" }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /orders/1
  # PUT /orders/1.json
  def update
    @order = Order.find(params[:id])

    respond_to do |format|
      if @order.update_attributes(params[:order])
        format.html { redirect_to @order, notice: 'Order was successfully updated.' }
        format.json { head :no_content }
        if @order.ship_date != params[:ship_date]
           OrderNotifier.shipped(@order).deliver
        end  
      else
        format.html { render action: "edit" }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1
  # DELETE /orders/1.json
  def destroy
    @order = Order.find(params[:id])
    @order.destroy

    respond_to do |format|
      format.html { redirect_to orders_url }
      format.json { head :no_content }
    end
  end
end
