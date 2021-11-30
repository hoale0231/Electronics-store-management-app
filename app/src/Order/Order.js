import BootstrapTable from "react-bootstrap-table-next";
import { Button, Form, Row, Col, FloatingLabel } from 'react-bootstrap'
import { useState, useEffect } from "react";
import OrderDescription from "./OrderDescription";


export default function Order() {
  const [orderDescription, setOrderDescription] = useState(-1)
  const [order, setOrder] = useState([]);


  const columns = [
    { dataField: "ID", text: "Order ID"},
    { dataField: "TimeCreated", text: "Time Created"},
    { dataField: "SumPrices", text: "Sum Prices"},
    { dataField: "ID_Customer", text: "Customer ID"},
    { dataField: "ID_Employee", text: "Employee ID"},
    { dataField: "ID_Ad", text: "CTKM ID", }
  ];

  useEffect(() => {
    fetch("/api/order/all")
      .then((response) => {
        if (response.ok) {
          return response.json()
        }
        throw response
      })
      .then((data) => { setOrder(data); })
      .catch((error) => {
        console.error("Error fetching data: ", error);
      })
  }, [])

  const deleteOrder = function (id) {
    fetch("/api/order/remove?id=" + id, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    })
      .then((response) => {
        if (response.ok) {
          const index = order.findIndex((e => e.id === id))
          order.splice(index, 1)
          setOrder(order)
          setOrderDescription(-1)
          return response.json()
        }
        throw response
      })

  }

  const rowEvents = {
    onClick: (e, row, rowIndex) => {
      setOrderDescription(row.ID)
    },
  };

  return (
    <div className="popup_container">
      <Button className="customButton" variant="success" onClick={() => { setOrderDescription(0) }}>Add Order</Button>

      <div className="table-custom">
        {/* https://react-bootstrap-table.github.io/react-bootstrap-table2/docs/about.html  */}
        <BootstrapTable keyField="id" data={order} columns={columns} rowEvents={rowEvents}/>
      </div>
      {/* <div className="container">
        <Button variant="success" onClick={() => { loadData(false) }}>Load More</Button>
      </div> */}
      <div>
        {orderDescription === -1 ? <p/> : orderDescription === 0 ?
          <OrderDescription id={orderDescription} setOrderDescription={setOrderDescription} action={'Add'}/> :
          <OrderDescription id={orderDescription} setOrderDescription={setOrderDescription} deleteOrder={deleteOrder} action={'Edit'}/>}
      </div>
    </div>
  );
}