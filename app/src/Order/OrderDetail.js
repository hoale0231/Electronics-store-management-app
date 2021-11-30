import { Modal, Button, Form, Row, Col } from 'react-bootstrap';
import BootstrapTable from "react-bootstrap-table-next";
import { useState, useEffect } from "react";
import "./OrderDetail.css";

export default function OrderDetail(props) {
  const {id, setDetail} = props
  const [info, setInfo] = useState([])

  useEffect(() => {
    fetch("/get/detail?id=" + id)
      .then((response) => {
        if (response.ok) {
          return response.json()
        } else {
          response.text().then(text => { alert(text);})
        }
      })
      .then((data) => {console.log(data); setInfo(data)})
      .catch((error) => {
        console.error("Error fetching data: ", error);
      })
  }, [id])

  const columns = [
    { dataField: "ID_Order", text: "Order ID"},
    { dataField: "Product_Name", text: "Product Name"},
    { dataField: "Product_Type", text: "Product Type"},
    { dataField: "Device_Type", text: "Device Type"},
    { dataField: "Product_Price", text: "Product Price"},
    { dataField: "Quantity", text: "Quantity"},
  ];

  return (
    <div className="popup-background">
      <Modal.Dialog className="popup" size="lg">
        <Modal.Header closeButton onClick={() => setDetail(false)}>
          <Modal.Title>Detail</Modal.Title>
        </Modal.Header>
        <Modal.Body className="body-popup">
            <BootstrapTable keyField="id" data={info} columns={columns}/>
        </Modal.Body>
      </Modal.Dialog>
    </div>
  )
}